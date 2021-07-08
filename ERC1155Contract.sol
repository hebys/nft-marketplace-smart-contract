// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @author Hebys development team
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC1155Contract is
    Context,
    AccessControlEnumerable,
    ERC1155Burnable,
    ERC1155Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    struct Royalty {
        uint256 id; // NFT Id
        address to; //  NFT Creator Address
        uint256 royaltyRate; //   NFT Royalty rate
    }

    mapping(uint256 => Royalty) public royalties;
    uint256 public maximumRoyaltyRate; //Maximum Royalty Rate

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        uint256 royaltyRate,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory data
    ) public virtual {
        // TODO Figure out signature that wanted next line. contract address + token id ?
        // require(_msgSender() == ecrecover(keccak256(abi.encodePacked(this, id)), v, r, s), "owner should sign tokenId");
        require(to != address(0), "ERC1155: mint to the zero address");
        // require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
        setRoyalty(to, id, royaltyRate);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory royaltyRates,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have minter role to mint"
        );
        require(
            ids.length == royaltyRates.length,
            "ERC1155: ids and royalties length mismatch"
        );

        _mintBatch(to, ids, amounts, data);
        setRoyaltyBatch(to, ids, royaltyRates);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setMaximumRoyaltyRate(uint256 royaltyRate) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "NOT_AUTHORIZED");

        maximumRoyaltyRate = royaltyRate;
    }

    function setRoyalty(
        address to,
        uint256 id,
        uint256 royaltyRate
    ) internal returns (Royalty memory) {
        require(
            maximumRoyaltyRate >= royaltyRate,
            "ROYALTY_RATE_CAN_NOT_THAN_MAXIMUM_RATE"
        );
        royalties[id].to = to;
        royalties[id].id = id;
        royalties[id].royaltyRate = royaltyRate;
        return royalties[id];
    }

    function setRoyaltyBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory royaltyRates
    ) internal returns (bool) {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                maximumRoyaltyRate >= royaltyRates[i],
                "ROYALTY_RATE_CAN_NOT_THAN_MAXIMUM_RATE"
            );
            royalties[ids[i]].to = to;
            royalties[ids[i]].id = ids[i];
            royalties[ids[i]].royaltyRate = royaltyRates[i];
        }

        return true;
    }

    function getRoyalty(uint256 id) public view returns (Royalty memory) {
        return royalties[id];
    }

    function getRoyaltyAddress(uint256 id) public view returns (address) {
        return royalties[id].to;
    }

    function getRoyaltyRate(uint256 id) public view returns (uint256) {
        return royalties[id].royaltyRate;
    }
}
