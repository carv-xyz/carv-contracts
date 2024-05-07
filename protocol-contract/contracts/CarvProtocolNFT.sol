// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract CarvProtocolNFT is ERC721Upgradeable, AccessControlUpgradeable {
    bytes32 public constant MINETR_ROLE = keccak256("MINETR_ROLE");

    bool public can_transfer;

    /**
        @notice Initializes CompaignsService, creates and grants {msg.sender} the admin role,
     */

    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        can_transfer = false;
        __ERC721_init(_name, _symbol);

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

    function mint(
        address _to,
        uint256 _tokenId
    ) external onlyRole(MINETR_ROLE) {
        super._mint(_to, _tokenId);
    }

    function batchMint(
        address[] calldata _receivers,
        uint256 _tokenIdStart
    ) external onlyRole(MINETR_ROLE) {
        for (uint256 i = 0; i < _receivers.length; i++) {
            super._mint(_receivers[i], _tokenIdStart + i);
        }
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
    function set_can_transfer(
        bool _can_transfer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        can_transfer = _can_transfer;
    }
}
