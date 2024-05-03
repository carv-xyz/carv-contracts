// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract CarvProtocolNFT is ERC721Upgradeable, AccessControlUpgradeable {
    bytes32 public constant MINETR_ROLE = keccak256("MINETR_ROLE");

    bool public can_transfer;

    modifier only_admin() {
        _only_admin();
        _;
    }

    function _only_admin() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "sender doesn't have admin role"
        );
    }

    modifier only_minters() {
        _only_minters();
        _;
    }

    function _only_minters() private view {
        require(
            hasRole(MINETR_ROLE, msg.sender),
            "sender doesn't have minter role"
        );
    }

    /**
        @notice Initializes CompaignsService, creates and grants {msg.sender} the admin role,
     */
    function __CarvProtocolNFT_init(
        string memory _name,
        string memory _symbol
    ) public initializer {
        can_transfer = false;
        __ERC721_init(_name, _symbol);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(address _to, uint256 _tokenId) external only_minters {
        super._mint(_to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override {
        require(can_transfer, "can not support transfer");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(can_transfer, "can not support transfer");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(can_transfer, "can not support transfer");
    }

    /**
        @notice set_can_transfer
     */
    function set_can_transfer(bool _can_transfer) external only_admin {
        can_transfer = _can_transfer;
    }

    function add_minter_role(address _minter_address) external only_admin {
        _setupRole(MINETR_ROLE, _minter_address);
    }
}
