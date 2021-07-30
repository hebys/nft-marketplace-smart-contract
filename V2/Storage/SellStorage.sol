// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Lib/SellLib.sol";

/**
 * @title SellStorageContract
 * @dev Implements NFT sell process
 * @author Hebys development team
 **/

contract SellStorageContract is AccessControl {
    bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyWriter() {
        require(hasRole(WRITER_ROLE, msg.sender), "NOT_WRITER_ADDRESS");
        _;
    }

    modifier onlyReader() {
        require(hasRole(READER_ROLE, msg.sender), "NOT_WRITER_ADDRESS");
        _;
    }

    constructor() {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    event LOGSellItem(SellLib.Sell _sell);
    event LOGAuctionBid(SellLib.Bid _bid);

    address public minter;
    address payable public ownerAddress;

    mapping(uint256 => SellLib.Sell) public sales;
    mapping(uint256 => SellLib.Bid) public bids;
    mapping(uint256 => SellLib.Metadata) public metadataList;

    function sellRegister(SellLib.Sell memory _sell)
        external
        onlyWriter
        returns (bool)
    {
        setSaleItem(_sell);
        return true;
    }

    function setSaleItem(SellLib.Sell memory _sell)
        internal
        returns (SellLib.Sell memory)
    {
        sales[_sell.sellId].sellId = _sell.sellId;
        sales[_sell.sellId].ownerAddress = _sell.ownerAddress;
        sales[_sell.sellId].nftCreatorContract = _sell.nftCreatorContract;
        sales[_sell.sellId].tokenId = _sell.tokenId;
        sales[_sell.sellId].saleQuantity = _sell.saleQuantity;
        sales[_sell.sellId].unitPrice = _sell.unitPrice;
        sales[_sell.sellId].isPrivateSell = _sell.isPrivateSell;
        sales[_sell.sellId].privateSellAddress = _sell.privateSellAddress;
        sales[_sell.sellId].isSale = true;
        sales[_sell.sellId].sellTypeEnum = _sell.sellTypeEnum;
        sales[_sell.sellId].minumumBid = _sell.minumumBid;
        sales[_sell.sellId].topBid = _sell.topBid;
        sales[_sell.sellId].auctionEndTime = _sell.auctionEndTime;
        sales[_sell.sellId].incrementQty = _sell.incrementQty;
        emit LOGSellItem(_sell);
        return sales[_sell.sellId];
    }

    function setWriterRole(address _writerAddress) public {
        require(hasRole(MINTER_ROLE, msg.sender), "NOT_MINTER_ADDRESS");
        _setupRole(WRITER_ROLE, _writerAddress);
    }

    function setReaderRole(address _writerAddress) public {
        require(hasRole(MINTER_ROLE, msg.sender), "NOT_MINTER_ADDRESS");
        _setupRole(READER_ROLE, _writerAddress);
    }

    function getSellItem(uint256 _sellId)
        public
        view
        onlyReader
        returns (SellLib.Sell memory)
    {
        return sales[_sellId];
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getIsDefinedSellId(uint256 _sellId) external view returns (bool) {
        return sales[_sellId].ownerAddress == address(0);
    }

    function updateUnitPrice(uint256 _sellId, uint256 _unitPrice)
        external
        onlyWriter
        returns (uint256)
    {
        sales[_sellId].unitPrice = _unitPrice;
        return sales[_sellId].unitPrice;
    }

    function setSaleStatus(uint256 _sellId, bool _isSale)
        external
        onlyWriter
        returns (bool)
    {
        sales[_sellId].isSale = _isSale;
        return sales[_sellId].isSale;
    }

    function updateSaleQuantity(uint256 _sellId, uint256 _quantity)
        external
        onlyWriter
        onlyWriter
        returns (uint256)
    {
        sales[_sellId].saleQuantity = _quantity;
        return sales[_sellId].saleQuantity;
    }

    function setAuctionBid(
        uint256 _sellId,
        address _bidderAddress,
        uint256 _bidPrice
    ) external onlyWriter returns (bool) {
        bids[_sellId].sellId = _sellId;
        bids[_sellId].topBidAddress = _bidderAddress;
        bids[_sellId].topBid = _bidPrice;
        emit LOGAuctionBid(bids[_sellId]);
        return true;
    }

    function getAuctionTopBid(uint256 _sellId)
        external
        view
        onlyReader
        returns (uint256)
    {
        return bids[_sellId].topBid;
    }

    function getAuctionTopBidderAddress(uint256 _sellId)
        external
        view
        onlyReader
        returns (address)
    {
        return bids[_sellId].topBidAddress;
    }

    function getAuctionTopBidAndBidderAddress(uint256 _sellId)
        external
        view
        onlyReader
        returns (SellLib.Bid memory)
    {
        return bids[_sellId];
    }
}
