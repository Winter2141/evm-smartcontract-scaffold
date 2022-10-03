// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

/**
 * @dev Interface of the Factory for NFT721 & NFT1155.
 */
interface IFactory {
    function createCollection(string memory name, string memory symbol, string memory uri) external returns (address);

    event Deploy(address indexed collection, address owner);
}
