// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Lib/SellLib.sol";

/**
 * @title FeeStorageContract
 * @dev Implements NFT sell process
 * @author Hebys development team
 **/

contract FeeStorageContract is AccessControl {
    bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyWriter() {
        require(hasRole(WRITER_ROLE, msg.sender), "NOT_WRITER_ADDRESS");
        _;
    }

    modifier onlyReader() {
        require(hasRole(READER_ROLE, msg.sender), "NOT_READER_ADDRESS");
        _;
    }

    constructor() {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    event LOGFeeOverride(FeeOverride _fee);

    struct FeeOverride {
        address _address;
        uint256 feeRate;
        address providerAddress;
    }

    address public minter;
    address public feeWalletAddress;
    uint256 public defaultFeeRate;

    mapping(address => FeeOverride) public feeOverrides;

    function setFeeOverride(
        address _address,
        uint256 _feeRate,
        address _providerAddress
    ) public onlyWriter returns (FeeOverride memory) {
        feeOverrides[_address]._address = _address;
        feeOverrides[_address].feeRate = _feeRate;
        feeOverrides[_address].providerAddress = _providerAddress;
        return feeOverrides[_address];
    }

    function setFeeOverrideBatch(
        address[] memory _address,
        uint256[] memory _feeRates,
        address[] memory _providerAddress
    ) public onlyWriter returns (bool) {
        for (uint256 i = 0; i < _address.length; i++) {
            feeOverrides[_address[i]]._address = _address[i];
            feeOverrides[_address[i]].feeRate = _feeRates[i];
            feeOverrides[_address[i]].providerAddress = _providerAddress[i];
            emit LOGFeeOverride(feeOverrides[_address[i]]);
        }

        return true;
    }

    function setWriterRole(address _writerAddress) public {
        require(hasRole(MINTER_ROLE, msg.sender), "NOT_MINTER_ADDRESS");
        _setupRole(WRITER_ROLE, _writerAddress);
    }

    function setReaderRole(address _writerAddress) public {
        require(hasRole(MINTER_ROLE, msg.sender), "NOT_MINTER_ADDRESS");
        _setupRole(READER_ROLE, _writerAddress);
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function setFeeWalletAddress(address _feeWalletAddress) public onlyWriter {
        feeWalletAddress = _feeWalletAddress;
    }

    function setDefaultFeeRate(uint256 _feeRate) public onlyWriter {
        defaultFeeRate = _feeRate;
    }

    function getFeeWalletAddress() public view onlyReader returns (address) {
        return feeWalletAddress;
    }

    function getFee(address _address)
        external
        view
        onlyReader
        returns (uint256)
    {
        uint256 _fee = defaultFeeRate;
        if (feeOverrides[_address]._address != address(0)) {
            _fee = feeOverrides[_address].feeRate;
        }

        return _fee;
    }
}
