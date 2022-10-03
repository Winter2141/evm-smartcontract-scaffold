// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract NFT721 is ERC721, Ownable {
    string _baseTokenURI;
    uint256 public index;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(string memory cid) external onlyOwner returns (uint256) {
        index++;
        _safeMint(tx.origin, index, cid);
        return index;
    }

    function burn(uint256 tokenId) external onlyOwner {
        require(ownerOf(tokenId) == tx.origin, "Burn: caller is not owner");
        _burn(tokenId);
    }
}
