// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "../Lib/SellLib.sol";

/**
 * @title Validator
 * @dev Implements NFT sell process
 * @author Hebys development team
 **/

contract Validator  {

    function validateSell(SellLib.Sell memory _sell) internal view returns (bool) {
        require(
            _sell.saleQuantity != uint256(0),
            "SALE_QUANTITY_CAN_NOT_BE_ZERO"
        );
        
        require(msg.sender == _sell.ownerAddress,"NOT_TOKEN_OWNER");
        if (
            _sell.isPrivateSell == true &&
            _sell.privateSellAddress == address(0)
        ) {
            revert("INVALID_PRIVATE_SELL_ADDRESS");
        }
        
        if (
            _sell.sellTypeEnum != SellLib.SellTypeEnum.DirectSell  &&
            block.timestamp  >= _sell.auctionEndTime
        ) {
            revert("PAST_AUCTION_DATE");
        }
        return true;
    }

    function validateBid(uint256 _sellId, address _bidderAddress) internal view returns (bool) {
        require(msg.sender == _bidderAddress,"THE_SENDER_IS_NOT_BIDDER_ADDRESS");
        require(msg.value != uint256(0),"BID_PRICE_CAN_NOT_BE_ZERO");
        require(_sellId != uint256(0),"SELL_ID_CAN_NOT_BE_ZERO");

        return true;
    }
    
    function validateWithdraw(uint256 _sellId, address _to) internal view returns (bool) {
        require(_sellId != uint256(0),"SELL_ID_CAN_NOT_BE_ZERO");
        require(_to == msg.sender, "THE_SENDER_IS_NOT_TO_ADDRESS");
        require(_to != address(0), "INVALID_ADDRESS");
        require(msg.value != uint256(0), "SALE_AMOUNT_CAN_NOT_BE_ZERO");

        
        return true;
    }

    function validateGetSellItem(SellLib.Sell memory _sell,address _to, uint256 _amount) internal view returns (bool) {
       require(_sell.isSale != false, "NOT_FOR_SALE");
            require(_sell.ownerAddress != address(0), "SELL_ID_NOT_FOUND");
            require(
                _sell.unitPrice <= msg.value,
                "INSUFFICIENT_SALE_AMOUNT"
            );
            if (
                _sell.isPrivateSell == true &&
                _sell.privateSellAddress != _to
            ) {
                revert("NO_PURCHASE_AUTHORITY");
            }

            require(
                _sell.saleQuantity >= _amount,
                "MORE_SALES_THAN_TOKEN_BALANCE"
            );
            
        return true;
    }
}
