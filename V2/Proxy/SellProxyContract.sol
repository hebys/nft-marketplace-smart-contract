// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Lib/SellLib.sol";
import "../Validator/Validator.sol";
import "../Interface/ISellStorage.sol";
import "../Interface/IERC1155.sol";
import "../Interface/IFeeStorage.sol";

/**
 * @title SellProxy
 * @dev Implements NFT sell process
 * @author Hebys development team
 */

contract SellProxyContract is Validator {
    modifier pauseControl() {
        require(pause != true, "CONTRACT_PAUSED");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "NOT_MINTER_ADDRESS");
        _;
    }

    constructor(ISellStorage _sellStorage, IFeeStorage _feeStorage) {
        minter = msg.sender;
        sellStorage = _sellStorage;
        feeStorage = _feeStorage;
        pause = false;
    }

    using SafeMath for uint256;
    event BalanceOf(address _ownerAddress, uint256 _tokenId, bool success);

    address public minter;
    ISellStorage public sellStorage;
    IFeeStorage public feeStorage;
    address payable public ownerAddress;
    bool public pause;

    function register(SellLib.Sell memory _sell)
        public
        pauseControl
        returns (bool)
    {
        //Sell Data Validator
        Validator.validateSell(_sell);
        //Previously Sell Id Check
        {
            bool isDefinedSellId = sellStorage.getIsDefinedSellId(_sell.sellId);
            require(isDefinedSellId == true, "SELL_ID_PREVIOUSLY_DEFINED");
        }

        //Proxy Authorıze Check
        {
            bool isApproved = IERC1155(_sell.nftCreatorContract)
                .isApprovedForAll(_sell.ownerAddress, address(this));
            require(isApproved == true, "NOT_AUTHORIZED_CREATOR_CONTRACT");
        }

        //Token balance Check
        {
            uint256 tokenBalance = IERC1155(_sell.nftCreatorContract).balanceOf(
                _sell.ownerAddress,
                _sell.tokenId
            );
            require(tokenBalance != 0, "INSUFFICIENT_TOKEN_BALANCE");
            require(
                tokenBalance >= _sell.saleQuantity,
                "MORE_SALES_THAN_TOKEN_BALANCE"
            );
        }

        //register SellRegistry
        bool registerySellSuccess = sellStorage.sellRegister(_sell);
        require(registerySellSuccess == true, "SELL_ITEM_NOT_SAVED");

        return true;
    }

    function bid(uint256 _sellId, address bidderAddress)
        public
        payable
        pauseControl
        returns (bool)
    {
        //Bid Data Validator
        Validator.validateBid(_sellId, bidderAddress);

        //SellIdCheck Sell Id Check
        {
            bool isDefinedSellId = sellStorage.getIsDefinedSellId(_sellId);
            require(isDefinedSellId == false, "SELL_ID_NOT_FOUND");
        }
        //BidPrice Check
        {
            SellLib.Sell memory sellItem = sellStorage.getSellItem(_sellId);
            require(sellItem.isSale != false, "NOT_FOR_SALE");
            require(
                sellItem.minumumBid <= msg.value,
                "AMOUNT_LESS_THAN_THE_MINIMUM_BID_AMOUNT"
            );
            require(
                sellItem.sellTypeEnum != SellLib.SellTypeEnum.DirectSell,
                "THIS_SALE_CANNOT_BE_OFFERED"
            );
            if (
                sellItem.sellTypeEnum != SellLib.SellTypeEnum.DirectSell &&
                block.timestamp >= sellItem.auctionEndTime
            ) {
                //TODO: revert to require
                revert("PAST_AUCTION_DATE");
            }
            //BidPrice Check
            SellLib.Bid memory topAuction = sellStorage
                .getAuctionTopBidAndBidderAddress(_sellId);
            require(
                topAuction.topBid < msg.value,
                "YOU_MUST_EXCEED_THE_PREVIOUS_OFFER"
            );
            if (topAuction.topBid == uint256(0)) {} else {
                uint256 incrementTopBid = SafeMath.add(
                    topAuction.topBid,
                    sellItem.incrementQty
                );
                require(
                    incrementTopBid <= msg.value,
                    "YOU_MUST_EXCEED_THE_PREVIOUS_OFFER"
                );
            }

            //Refund of previous top bid
            bool successRevertTopBidPrice = sendPrice(
                topAuction.topBidAddress,
                topAuction.topBid
            );
            require(successRevertTopBidPrice, "BID_PRICE_REVERT_ERROR");
        }

        uint256 bidPrice = msg.value;
        bool setAuctionBidSuccess = sellStorage.setAuctionBid(
            _sellId,
            bidderAddress,
            bidPrice
        );
        require(setAuctionBidSuccess == true, "SET_AUCTION_NOT_SAVED");

        return true;
    }

    function closeAuction(uint256 _sellId) public pauseControl {
        SellLib.Sell memory sellItem = sellStorage.getSellItem(_sellId);
        require(
            sellItem.ownerAddress == msg.sender,
            "THE_SENDER_IS_NOT_TO_ADDRESS"
        );

        SellLib.Bid memory topAuction = sellStorage
            .getAuctionTopBidAndBidderAddress(_sellId);
        withdraw(
            sellItem,
            topAuction.topBidAddress,
            uint256(1),
            topAuction.topBid,
            topAuction.topBid
        );
        sellStorage.setSaleStatus(sellItem.sellId, false);
    }

    function updateUnitPrice(uint256 _sellId, uint256 _unitPrice)
        public
        pauseControl
    {
        SellLib.Sell memory sellItem = sellStorage.getSellItem(_sellId);
        require(
            sellItem.ownerAddress == msg.sender,
            "THE_SENDER_IS_NOT_TO_ADDRESS"
        );

        sellStorage.updateUnitPrice(sellItem.sellId, _unitPrice);
    }

    function closeAuctionForSystem(uint256[] memory _sellIds)
        public
        pauseControl
        onlyMinter
    {
        for (uint256 i = 0; i < _sellIds.length; i++) {
            SellLib.Sell memory sellItem = sellStorage.getSellItem(_sellIds[i]);
            SellLib.Bid memory topAuction = sellStorage
                .getAuctionTopBidAndBidderAddress(_sellIds[i]);
            withdraw(
                sellItem,
                topAuction.topBidAddress,
                uint256(1),
                topAuction.topBid,
                topAuction.topBid
            );
            sellStorage.setSaleStatus(sellItem.sellId, false);
        }
    }

    function purchase(
        uint256 _sellId,
        uint256 _amount,
        address payable _to
    ) public payable pauseControl returns (bool) {
        //Bid Data Validator
        Validator.validateWithdraw(_sellId, _to);

        //BidPrice Check
        {
            SellLib.Sell memory sellItem = sellStorage.getSellItem(_sellId);
            require(
                sellItem.sellTypeEnum == SellLib.SellTypeEnum.DirectSell,
                "NOT_PURCHASE_ITEM"
            );
            Validator.validateGetSellItem(sellItem, msg.sender, _amount);
            withdraw(sellItem, _to, _amount, sellItem.unitPrice, msg.value);
        }
        return true;
    }

    function calculateRoyaltyPrice(uint256 _totalPrice, uint256 _royaltyRate)
        internal
        pure
        returns (uint256)
    {
        uint256 calculatedRoyaltyPrice = SafeMath.div(
            SafeMath.mul(_totalPrice, _royaltyRate),
            100
        );

        return calculatedRoyaltyPrice;
    }

    function sendPrice(address _to, uint256 _price) internal returns (bool) {
        (bool successSendPrice, ) = _to.call{value: _price}("");
        return successSendPrice;
    }

    function withdraw(
        SellLib.Sell memory sellItem,
        address _to,
        uint256 _amount,
        uint256 _unitPrice,
        uint256 _price
    ) internal returns (bool) {
        uint256 totalPrice = SafeMath.mul(_amount, _unitPrice);
        require(totalPrice <= _price, "INSUFFICIENT_SALE_AMOUNT");

        //getRoyaltyRate
        SellLib.Royalty memory royalty = IERC1155(sellItem.nftCreatorContract)
            .getRoyalty(sellItem.tokenId);
        {
            require(royalty.to != address(0), "INVALID_ROYALTY_ADDRESS");
        }
        //Calculate NFT Creator Address RoyaltyPrice
        uint256 calculatedRoyaltyPrice = calculateRoyaltyPrice(
            totalPrice,
            royalty.royaltyRate
        );

        uint256 ownerPrice = totalPrice;
        //NFT Owner Price  (OwnerPrice - calculatedRoyaltyPrice)
        ownerPrice = SafeMath.sub(ownerPrice, calculatedRoyaltyPrice);

        uint256 feeRate = feeStorage.getFee(sellItem.ownerAddress);
        //NFT Marketplace Price   (totalPrice * feeRate) / 1000
        uint256 calculatedFeePrice = SafeMath.div(
            SafeMath.mul(totalPrice, feeRate),
            1000
        );

        //NFT Owner Price   (OwnerPrice - calculatedRoyaltyPrice)
        ownerPrice = SafeMath.sub(ownerPrice, calculatedFeePrice);
        {
            address marketplaceFeeWalletAddress = feeStorage
                .getFeeWalletAddress();
            require(
                marketplaceFeeWalletAddress != address(0),
                "FEE_WALLET_ADDRESS_NOT_FOUND"
            );

            //Marketplace Fee price Send
            bool successSendFeePrice = sendPrice(
                marketplaceFeeWalletAddress,
                calculatedFeePrice
            );
            require(successSendFeePrice, "FEE_PRICE_TRANSFER_FAILED");
        }
        {
            //Creator Royalty Price Send
            bool successSendRoyaltyPrice = sendPrice(
                royalty.to,
                calculatedRoyaltyPrice
            );
            require(successSendRoyaltyPrice, "ROYALTY_PRICE_TRANSFER_FAILED");
        }
        {
            bool successSendOwnerPrice = sendPrice(
                sellItem.ownerAddress,
                ownerPrice
            );
            require(successSendOwnerPrice, "OWNER_PRICE_TRANSFER_FAILED");
        }

        //Send NFT
        IERC1155(sellItem.nftCreatorContract).safeTransferFrom(
            sellItem.ownerAddress,
            _to,
            sellItem.tokenId,
            _amount,
            "0x0"
        );
        {
            uint256 calculatedSellQuantity = SafeMath.sub(
                sellItem.saleQuantity,
                _amount
            );
            sellStorage.updateSaleQuantity(
                sellItem.sellId,
                calculatedSellQuantity
            );
            if (calculatedSellQuantity == 0) {
                sellStorage.setSaleStatus(sellItem.sellId, false);
            }
        }
        return true;
    }

    function setSellStorageAddress(ISellStorage _sellRegisterAddress)
        public
        pauseControl
        onlyMinter
    {
        sellStorage = _sellRegisterAddress;
    }

    function pauseContract() public onlyMinter {
        pause = true;
    }

    function unPauseContract() public onlyMinter {
        pause = false;
    }

    function setFeeStorageAddress(IFeeStorage _feeRegisterAddress)
        public
        onlyMinter
    {
        feeStorage = _feeRegisterAddress;
    }

    function getBalance() public view pauseControl returns (uint256) {
        return address(this).balance;
    }
}
