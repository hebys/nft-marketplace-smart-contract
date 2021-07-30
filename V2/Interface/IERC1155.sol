// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "../Lib/SellLib.sol";

/**
 * @title IERC1155
 * @dev Implements NFT sell process
 * @author Hebys development team
 **/
 
interface IERC1155 {

    function isApprovedForAll(address _tokenOwnerAddress ,address _proxyContractAddress) external  returns (bool);

    function balanceOf(address _tokenOwnerAddress,uint256 _tokenId) external  view returns (uint256) ;
    
    function getRoyaltyAddress( uint256 _tokenId)  external view  returns (address) ;

    function getRoyalty( uint256 _tokenId) external view  returns (SellLib.Royalty memory) ;
    
    function getRoyaltyRate(uint256 _tokenId ) external view returns (uint256) ;

    function safeTransferFrom(address _fromAddress,address _toAdress,uint256 _tokenId,uint256 _amount, bytes memory data) external  ;
    
}
