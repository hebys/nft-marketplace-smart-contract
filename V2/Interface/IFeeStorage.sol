// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title IFeeStorage
 * @dev Implements NFT sell process
 * @author Hebys development team
 **/
 
interface IFeeStorage {

    function getFeeWalletAddress() external view returns (address);

    function getFee(address _address) external view returns (uint256);
}
