// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title SellRepositoryContract
 * @dev Implements NFT sell process
 * @author Hebys development team
 **/
 
contract SellLib  {

    enum SellTypeEnum {
        DirectSell,
        EnglishAuction,
        SpanishAuction
    }
    
    struct Sell {
        uint256 sellId; // OffChainDataSell ID
        address payable ownerAddress; //  NFT owner address
        uint256 tokenId; //   NFT tokenId
        uint256 unitPrice; //    NFT Unit Price
        uint256 saleQuantity; //     NFT Sale Quantity
        address nftCreatorContract; //      NFT Craetor contractAddress
        bool isSale; //       NFT sale true/false
        bool isPrivateSell; //        NFT Private Sell
        address privateSellAddress; //        NFT Private Sell
        SellTypeEnum sellTypeEnum;
        uint256 minumumBid;
        uint256 topBid;
        uint256 auctionEndTime;
        uint256 incrementQty;
    }
    
    struct Bid {
        uint256 sellId;
        uint256 topBid;
        address topBidAddress;
    }
    
    struct ProxyRegistry {
        uint256 sellId; // OffChainDataSell ID
        address sellStorageAddress;
        address feeStorageAddress;
    }
    
     struct Metadata {
        uint256 sellId; // OffChainDataSell ID
        bytes key;
        bytes value;
    }
    
    struct Royalty {
        uint256 id; // NFT Id
        address to; //  NFT Creator Address
        uint256 royaltyRate; //   NFT Royalty rate
    }
 
 
}
