// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../Lib/SellLib.sol";

/**
 * @title ISellStorage
 * @dev Implements NFT sell process
 * @author Hebys development team
 **/
 
interface ISellStorage {

    function sellRegister(SellLib.Sell memory _sell) external returns (bool);
    
    function setSaleStatus(uint256 _sellId, bool _isSale) external  returns (bool);
    
    function setAuctionBid(uint256 _sellId, address _bidderAddress,uint256 _bidPrice)  external  returns (bool);
    
    function getIsDefinedSellId(uint256 _sellId) external view returns (bool); 

    function getSellItem(uint256 _sellId) external  view returns (SellLib.Sell memory);

    function getAuctionTopBid(uint256 _sellId) external  view returns (uint256);
    
    function getAuctionTopBidderAddress(uint256 _sellId) external  view returns (address);
    
    function getAuctionTopBidAndBidderAddress(uint256 _sellId) external  view returns (SellLib.Bid memory);
   
    function updateSaleQuantity(uint256 _sellId, uint256 _quantity) external   returns (uint256); 
    
    function updateUnitPrice(uint256 _sellId, uint256 _unitPrice) external  returns (uint256);
   
}