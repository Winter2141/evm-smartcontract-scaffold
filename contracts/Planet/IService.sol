// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

interface IService {
    function platformAddress() external view returns (address);

    function platformFeeRate() external view returns (uint96);

    function royaltyOf(address collection, uint256 salePrice) external view returns (address, uint256);

    function kothOf(address collection, uint256 tokenId, uint256 salePrice) external view returns (address, uint256);

    function gammaLockOf(address collection, uint256 tokenId) external view returns (uint256);

    event Lock(address indexed collection, uint256 indexed tokenId, uint256 amount, address account);

    event Unlock(address indexed collection, uint256 indexed tokenId, address account);
}
