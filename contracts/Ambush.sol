// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract Ambush is ERC1155, IERC2981, Ownable, Pausable, ContextMixin, ReentrancyGuard {
    string public name = "Ambush";
    string public symbol = "ABS";

    uint256 public price;
    uint256 public royaltyPercent;
    string private baseURI;
    uint8[] private supplies;
    uint256 public maxSupply;
    uint256 private currentTokenId;
    uint256 private maxPerWalletPresale;
    uint256 private maxPerWalletGeneral;
    uint8 private isPresale;
    string public contractURL;
    bytes32 public merkleRoot;
    address proxyRegistryAddress;
    mapping(address => uint256) private _mintedInPresale;
    mapping(address => uint256) private _mintedInGeneral;
    address private primaryRecipient;
    address private secondaryRecipient;
    
    constructor(uint256 _price, string memory _baseURI) ERC1155(string(abi.encodePacked(_baseURI, "{id}"))) {
        price = _price;
        royaltyPercent = 1000;
        maxSupply = 2023;
        supplies = new uint8[](maxSupply);
        for (uint256 i = 0; i < maxSupply; i++) {
            supplies[i] = 0;
        }
        baseURI = _baseURI;
        currentTokenId = 0;

        maxPerWalletPresale = 1;
        maxPerWalletGeneral = 2;
        isPresale = 1;

        primaryRecipient = 0xc810792E7A896EE258FE22edbfde651c789e0ff4;
        secondaryRecipient = 0x04ae1F1aDc0eFdf0664F92FFD385982cf16E4e08;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////// Owner Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxPerWallet(uint256 _maxForPresale, uint256 _maxForGeneral) public onlyOwner {
        maxPerWalletPresale = _maxForPresale;
        maxPerWalletGeneral = _maxForGeneral;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setPrimaryRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "New recipient is the zero address.");

        primaryRecipient = _recipient;
    }

    function setSecondaryRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "New recipient is the zero address.");

        secondaryRecipient = _recipient;
    }

    function setRoyaltyPercent(uint256 _percent) external onlyOwner {
        royaltyPercent = _percent;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setIsPresale(uint8 _value) public onlyOwner {
        isPresale = _value;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    function airdrop(address _receiver) public onlyOwner {
        require(currentTokenId + 23 <= supplies.length, "NFT is sold out.");

        for (uint256 i = 0; i < 23; i++) {
            require(supplies[currentTokenId] == 0, "NFT is already minted.");
            _mint(_receiver, currentTokenId, 1, "");

            supplies[currentTokenId] += 1;
            currentTokenId += 1;
        }
    }

    function setProxyAddress(address _proxyAddress) public onlyOwner {
        proxyRegistryAddress = _proxyAddress;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////// View Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function isOnAllowlist(bytes32[] memory _proof, address _claimer) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_claimer));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function isInPresale() public view returns (uint8) {
        return isPresale;
    }

    function mintedBalanceOf(address _address, uint8 _isPresale) public view returns (uint256) {
        if (_isPresale == 1) {
            return _mintedInPresale[_address];
        }
        return _mintedInGeneral[_address];
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////// Mint Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function mintPresale(bytes32[] memory _proof) external payable {
        require(isPresale == 1, "It is general sale now.");
        require(isOnAllowlist(_proof, _msgSender()), "You are not on the allow list.");
        require(currentTokenId + 1 <= supplies.length, "NFT is sold out.");
        require(supplies[currentTokenId] == 0, "NFT is already minted.");
        require(_mintedInPresale[_msgSender()] + 1 <= maxPerWalletPresale, "You can not mint anymore.");
        require(msg.value >= price, "Not enough to pay for that");

        payable(primaryRecipient).transfer(msg.value);

        _mint(msg.sender, currentTokenId, 1, "");

        supplies[currentTokenId] += 1;
        currentTokenId += 1;
        _mintedInPresale[_msgSender()] = _mintedInPresale[_msgSender()] + 1;
    }

    function mintGeneral() external payable {
        require(isPresale == 0, "It is presale now.");
        require(currentTokenId + 1 <= supplies.length, "NFT is sold out.");
        require(supplies[currentTokenId] == 0, "NFT is already minted.");
        require(_mintedInGeneral[_msgSender()] + 1 <= maxPerWalletGeneral, "You can not mint anymore.");
        require(msg.value >= price, "Not enough to pay for that");

        payable(primaryRecipient).transfer(msg.value);

        _mint(msg.sender, currentTokenId, 1, "");

        supplies[currentTokenId] += 1;
        currentTokenId += 1;
        _mintedInGeneral[_msgSender()] = _mintedInGeneral[_msgSender()] + 1;
    }


    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////// Opensea Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function totalSupply() public view returns(uint256) {
        return currentTokenId;
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId <= supplies.length - 1, "NFT does not exist");
        return baseURI;
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////// Royalty Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (secondaryRecipient, (_salePrice * royaltyPercent) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    function _msgSender() internal override view returns (address) {
        return ContextMixin.msgSender();
    }
}
