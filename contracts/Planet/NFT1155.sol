// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract NFT1155 is ERC1155, Ownable {
    using Strings for uint256;

    uint256 index;

    constructor(string memory name, string memory symbol) ERC1155(name, symbol) {}

    function uri(uint256 tokenId) external view override returns (string memory) {
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function mint(uint256 amount) external onlyOwner returns (uint256) {
        index++;
        _mint(tx.origin, index, amount, "");
        return index;
    }

    function mint(uint256 tokenId, uint256 amount) external onlyOwner {
        require(tokenId < index, "NFT1155: invalid token ID");
        _mint(tx.origin, tokenId, amount, "");
    }

    function burn(uint256 tokenId, uint256 amount) external onlyOwner {
        _burn(tx.origin, tokenId, amount);
    }
}
