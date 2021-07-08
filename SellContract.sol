// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Sell
 * @dev Implements NFT sell process
 * @author Hebys development team
 */
contract SellContract {
    constructor() {
        minter = msg.sender;
    }

    using SafeMath for uint256;
    event balanceOf(address _ownerAddress, uint256 _tokenId, bool success);
    event creatorRoyaltyAddress(
        address _royaltyAddress,
        uint256 _tokenId,
        bool success
    );
    event creatorRoyaltyRate(
        uint256 _royaltyRate,
        uint256 _tokenId,
        bool success
    );

    event LOGSellItem(uint256 sellId, address ownerAddress, uint256 tokenId);

    struct Seller {
        uint256 sellId; // OffChainDataSell ID
        address payable ownerAddress; //  NFT owner address
        uint256 tokenId; //   NFT tokenId
        uint256 unitPrice; //    NFT Unit Price
        uint256 saleQuantity; //     NFT Sale Quantity
        address nftCreatorContract; //      NFT Craetor contractAddress
        bool isSale; //       NFT sale true/false
        bool isPrivateSell; //        NFT Private Sell
        address privateSellAddress; //        NFT Private Sell
    }

    address public minter;
    address payable public feeWalletAddress;
    address payable public ownerAddress;
    uint256 public feeRate;

    mapping(uint256 => Seller) public sales;

    Seller[] public sellers;

    function setForSale(
        uint256 _sellId,
        address payable _ownerAddress,
        uint256 _tokenId,
        uint256 _unitPrice,
        uint256 _saleQuantity,
        address _nftCreatorContractAddress,
        bool _isPrivateSell,
        address _privateSellAddress
    ) public returns (Seller memory) {
        require(_saleQuantity != uint256(0), "SALE_QUANTITY_CAN_NOT_BE_ZERO");
        require(msg.sender == _ownerAddress, "NOT_TOKEN_OWNER");
        if (_isPrivateSell == true && _privateSellAddress == address(0)) {
            revert("INVALID_PRIVATE_SELL_ADDRESS");
        }

        //sell Id Check
        require(
            sales[_sellId].ownerAddress == address(0),
            "SELL_ID_PREVIOUSLY_DEFINED"
        );

        address creatorContractAddress = _nftCreatorContractAddress;
        address contractAddress = address(this);

        //Operator authorization inquiry for sales contract from creator contract
        (bool success, bytes memory result) =
            creatorContractAddress.call(
                abi.encodeWithSignature(
                    "isApprovedForAll(address,address)",
                    _ownerAddress,
                    contractAddress
                )
            );

        require(success, "NOT_AUTHORIZED_CREATOR_CONTRACT_CALL_ERROR");
        bool isApproved = abi.decode(result, (bool));
        require(isApproved != false, "NOT_AUTHORIZED_CREATOR_CONTRACT");

        //token balance control
        uint256 tokenBalance =
            getBalanceOfCallContract(
                _ownerAddress,
                creatorContractAddress,
                _tokenId
            );
        require(tokenBalance != 0, "INSUFFICIENT_TOKEN_BALANCE");
        require(tokenBalance >= _saleQuantity, "MORE_SALES_THAN_TOKEN_BALANCE");
        return
            setSaleItem(
                _sellId,
                _ownerAddress,
                _tokenId,
                _unitPrice,
                _saleQuantity,
                _nftCreatorContractAddress,
                _isPrivateSell,
                _privateSellAddress
            );
    }

    function setSaleItem(
        uint256 _sellId,
        address payable _ownerAddress,
        uint256 _tokenId,
        uint256 _unitPrice,
        uint256 _saleQuantity,
        address _nftCreatorContractAddress,
        bool _isPrivateSell,
        address _privateSellAddress
    ) internal returns (Seller memory) {
        sales[_sellId].sellId = _sellId;
        sales[_sellId].ownerAddress = _ownerAddress;
        sales[_sellId].nftCreatorContract = _nftCreatorContractAddress;
        sales[_sellId].tokenId = _tokenId;
        sales[_sellId].saleQuantity = _saleQuantity;
        sales[_sellId].unitPrice = _unitPrice;
        sales[_sellId].isPrivateSell = _isPrivateSell;
        sales[_sellId].privateSellAddress = _privateSellAddress;
        sales[_sellId].isSale = true;

        return sales[_sellId];
    }

    function setFeeWalletAddress(address payable _feeWalletAddress) public {
        //Contract generating address control
        require(msg.sender == minter, "NOT_MINTER_ADDRESS");
        feeWalletAddress = _feeWalletAddress;
    }

    function setFeeRate(uint256 _feeRate) public {
        //Contract generating address control
        require(msg.sender == minter, "NOT_MINTER_ADDRESS");
        feeRate = _feeRate;
    }

    function getSellItem(uint256 _sellId) public view returns (Seller memory) {
        return sales[_sellId];
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getAllSellItem() public view returns (Seller[] memory) {
        return sellers;
    }

    function getBalanceOfCallContract(
        address _ownerAddress,
        address _creatorContractAddress,
        uint256 _tokenId
    ) internal returns (uint256) {
        (bool success, bytes memory result) =
            _creatorContractAddress.call(
                abi.encodeWithSignature(
                    "balanceOf(address,uint256)",
                    _ownerAddress,
                    _tokenId
                )
            );

        require(success, "BALANCE_CALL_ERROR");

        emit balanceOf(_ownerAddress, _tokenId, success);
        return abi.decode(result, (uint256));
    }

    function getCreatorRoyaltyAddress(
        address _creatorContractAddress,
        uint256 _tokenId
    ) internal returns (address) {
        (bool success, bytes memory result) =
            _creatorContractAddress.call(
                abi.encodeWithSignature("getRoyaltyAddress(uint256)", _tokenId)
            );

        require(success, "CREATOR_FEE_ADDRESS_CALL_ERROR");

        emit creatorRoyaltyAddress(
            abi.decode(result, (address)),
            _tokenId,
            success
        );
        return abi.decode(result, (address));
    }

    function getCreatorRoyaltyRate(
        address _creatorContractAddress,
        uint256 _tokenId
    ) internal returns (uint256) {
        (bool success, bytes memory result) =
            _creatorContractAddress.call(
                abi.encodeWithSignature("getRoyaltyRate(uint256)", _tokenId)
            );

        require(success, "CREATOR_ROYALTY_RATE_CALL_ERROR");

        emit creatorRoyaltyRate(
            abi.decode(result, (uint256)),
            _tokenId,
            success
        );
        return abi.decode(result, (uint256));
    }

    function updateUnitPrice(uint256 _sellId, uint256 _unitPrice)
        public
        returns (Seller memory)
    {
        require(sales[_sellId].ownerAddress != msg.sender, "NOT_AUTHORIZED");
        sales[_sellId].unitPrice = _unitPrice;
        return sales[_sellId];
    }

    function setSaleStatus(uint256 _sellId, bool _isSale)
        public
        returns (Seller memory)
    {
        require(sales[_sellId].ownerAddress != msg.sender, "NOT_AUTHORIZED");
        sales[_sellId].isSale = _isSale;
        return sales[_sellId];
    }

    function updateSaleQuantity(uint256 _sellId, uint256 _saleQuantity, uint256 quantity)
        internal
       
    {
        sales[_sellId].saleQuantity = SafeMath.sub(sales[_sellId].saleQuantity,quantity );
    }

    function withdraw(
        uint256 _sellId,
        uint256 _amount,
        address payable _to
    ) public payable {
        require(_to == msg.sender, "NOT_AUTHORIZED");
        require(_to != address(0), "INVALID_ADDRESS");
        require(sales[_sellId].isSale != false, "NOT_FOR_SALE");
        require(msg.value != uint256(0), "SALE_AMOUNT_CAN_NOT_BE_ZERO");
        if (
            sales[_sellId].isPrivateSell == true &&
            sales[_sellId].privateSellAddress != _to
        ) {
            revert("NO_PURCHASE_AUTHORITY");
        }

        uint256 _saleQuantity = sales[_sellId].saleQuantity;
        require(_saleQuantity >= _amount, "MORE_SALES_THAN_TOKEN_BALANCE");
        //Calculate Total Price (amount * unitPrice)
        uint256 totalPrice = SafeMath.mul(_amount, sales[_sellId].unitPrice);
        require(totalPrice <= msg.value, "INSUFFICIENT_SALE_AMOUNT");

        //token balance control
        uint256 tokenBalance =
            getBalanceOfCallContract(
                sales[_sellId].ownerAddress,
                sales[_sellId].nftCreatorContract,
                sales[_sellId].tokenId
            );
        require(tokenBalance != 0, "INSUFFICIENT_TOKEN_BALANCE");
        require(tokenBalance >= _amount, "LESS_TOKEN_BALANCE_THAN_AMOUNT");

        address creatorContractAddress = sales[_sellId].nftCreatorContract;
        //getRoyaltyRate
        uint256 royaltyRate =
            getCreatorRoyaltyRate(
                creatorContractAddress,
                sales[_sellId].tokenId
            );
        require(royaltyRate != uint256(0), "ROYALTY_RATE_CAN_NOT_BE_ZERO");

        //getRoyaltyAddress  NFT creator Address
        address creatorAddress =
            getCreatorRoyaltyAddress(
                creatorContractAddress,
                sales[_sellId].tokenId
            );
        require(creatorAddress != address(0), "INVALID_ROYALTY_ADDRESS");

        address _ownerAddress = sales[_sellId].ownerAddress;
        require(_ownerAddress != address(0), "INVALID_ROYALTY_ADDRESS");

        uint256 _tokenId = sales[_sellId].tokenId;
       
        //Calculate NFT Creator Address RoyaltyPrice
        uint256 calculatedRoyaltyPrice =
            SafeMath.div(SafeMath.mul(totalPrice, royaltyRate), 100);

        uint256 OwnerPrice = totalPrice;
        //NFT Owner Price  (OwnerPrice - calculatedRoyaltyPrice)
        OwnerPrice = SafeMath.sub(OwnerPrice, calculatedRoyaltyPrice);

        updateSaleQuantity(_sellId, _saleQuantity,_amount);

        //NFT Marketplace Price   (totalPrice * feeRate) / 1000
        uint256 calculatedFeePrice =
            SafeMath.div(SafeMath.mul(totalPrice, feeRate), 1000);
        address toAddress = _to;
        //NFT Owner Price   (OwnerPrice - calculatedRoyaltyPrice)
        OwnerPrice = SafeMath.sub(OwnerPrice, calculatedFeePrice);
        uint256 quantity = _amount;

        //Marketplace Fee price Send
        (bool successSendFeePrice, ) =
            feeWalletAddress.call{value: calculatedFeePrice}("");
        require(successSendFeePrice, "FEE_PRICE_TRANSFER_FAILED");
        //Creator Royalty Price Send
        (bool successSendRoyaltyPrice, ) =
            creatorAddress.call{value: calculatedRoyaltyPrice}("");
        require(successSendRoyaltyPrice, "ROYALTY_PRICE_TRANSFER_FAILED");
        //Owner Sale Price Send
        (bool successSendOwnerPrice, ) =
            creatorAddress.call{value: OwnerPrice}("");
        require(successSendOwnerPrice, "OWNER_PRICE_TRANSFER_FAILED");

        //Send NFT
        (bool succesNFTTransfer, bytes memory returnData) =
            sendTokenTransfer(
                creatorContractAddress,
                _ownerAddress,
                toAddress,
                _tokenId,
                quantity
            );

        require(succesNFTTransfer, "TOKEN_TRANSFER_FAILED");
    }

    function sendTokenTransfer(
        address creatorContractAddress,
        address _fromAddress,
        address _toAdress,
        uint256 _tokenId,
        uint256 _amount
    ) internal returns (bool, bytes memory) {
        (bool succesNFTTransfer, bytes memory returnData) =
            creatorContractAddress.call(
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)",
                    _fromAddress,
                    _toAdress,
                    _tokenId,
                    _amount,
                    "0x0"
                )
            );

        require(succesNFTTransfer, "TOKEN_TRANSFER_FAILED");
        return (succesNFTTransfer, returnData);
    }
}
