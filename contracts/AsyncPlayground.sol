// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AsyncPlayground is ERC1155, Ownable, ReentrancyGuard {
    string public name = "Async Playground";
    string public symbol = "ASYNCP";

    enum SALE_TYPE { PUBLICSALE, PRESALE }
    SALE_TYPE private saleType = SALE_TYPE.PRESALE;
    mapping(address => uint) private holdCount;
    uint8 private PRESALE_MAX_HOLD_COUNT = 1;
    uint8 private PUBLICSALE_MAX_HOLD_COUNT = 5;
    uint8[] private supplies;
    address[] private whitelist; 
    uint256 private currentTokenId = 0;
    string private baseURI = "ipfs://QmTubr1R1AMgWJgQpzakZTScHbdjbHtC7Sj6sSbr25Muhf/";
    
    constructor(uint256 _maxSupply, string memory _baseURI) ERC1155(string(abi.encodePacked(_baseURI, "{id}"))) {
        supplies = new uint8[](_maxSupply);
        for (uint256 i = 0; i < _maxSupply; i++) {
            supplies[i] = 0;
        }
        baseURI = _baseURI;
    }

    function isPresale() public view returns(SALE_TYPE) {
        return saleType;
    }

    function setPreSale() public onlyOwner {
        saleType = SALE_TYPE.PRESALE;
    }

    function setPublicSale() public onlyOwner {
        saleType = SALE_TYPE.PUBLICSALE;
    }

    function setBaseUri(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelist(address[] memory list) public onlyOwner {
        whitelist = list; 
    }

    function checkInWhitelist(address _addr) public view returns(uint8) {
        for (uint256 i = 0 ;i < whitelist.length ; i++){
            if (whitelist[i] == _addr) {
                return 1 ; 
            }
        } 
        return 0 ; 
    }

    function totalSupply() public view returns(uint256) {
        return currentTokenId;
    }

    function currentHoldCount() public view returns(uint) {
        return holdCount[msg.sender];
    }

    // For putting NFT on Opensea
    function uri(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId <= supplies.length - 1, "NFT does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function mint() public {
        uint maxHoldCount = PRESALE_MAX_HOLD_COUNT;
        if (saleType == SALE_TYPE.PRESALE) {
            require(checkInWhitelist(msg.sender) == 1, "You are not in the whitelist.");
        } else if (saleType == SALE_TYPE.PUBLICSALE) {
            maxHoldCount = PUBLICSALE_MAX_HOLD_COUNT;
        }

        require(holdCount[msg.sender] < maxHoldCount, "You can't mint more.");

        require(currentTokenId <= supplies.length - 1, "NFT is sold out.");

        require(supplies[currentTokenId] == 0, "NFT is already minted.");

        _mint(msg.sender, currentTokenId, 1, "");

        supplies[currentTokenId] += 1;
        holdCount[msg.sender] += 1;
        currentTokenId += 1;        
    }
}