// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract CarvProtocolNFT is ERC721Upgradeable, AccessControlUpgradeable {
    bytes32 public constant MINETR_ROLE = keccak256("MINETR_ROLE");
    bool public can_transfer;
    uint256 private _cur_token_id;

    event Minted(address to, uint256 token_id);
    event VerifierWeightChanged(address from, address to);

    mapping(address => uint256) public address_vote_weight;
    // owner -> tokenId -> receiver
    mapping(address => mapping(uint256 => address))
        private _verifier_delegate_addresss_map;
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
        _cur_token_id = 1;

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

    /**
        @notice mint
     */
    function mint(address _to) external only_minters {
        // TODO 1 change to gas less
        // TODO 2 one day limit check
        super._mint(_to, _cur_token_id);

        address_vote_weight[_to]++;
        _cur_token_id++;
        emit Minted(_to, _cur_token_id);
    }

    /**
        @notice verifier_delegate
     */
    function verifier_delegate(
        address[] calldata target_address_arr,
        uint256[] calldata token_ids
    ) external {
        // TODO 1 change to gas less
        // TODO 2 one day limit check

        for (uint256 i = 0; i < token_ids.length; i++) {
            require(
                ownerOf(token_ids[i]) == msg.sender,
                "CarvProtocolService: not owner"
            );
            require(
                _verifier_delegate_addresss_map[msg.sender][token_ids[i]] ==
                    address(0),
                "already been deplegtade"
            );
            _verifier_weight_changed(msg.sender, target_address_arr[i]);
            _verifier_delegate_addresss_map[msg.sender][
                token_ids[i]
            ] = target_address_arr[i];
        }
    }

    /**
        @notice verifier_redelegate
     */
    function verifier_redelegate(
        address[] calldata target_address_arr,
        uint256[] calldata token_ids
    ) public {
        // TODO 1 change to gas less
        // TODO 2 one day limit check
        for (uint256 i = 0; i < token_ids.length; i++) {
            require(
                ownerOf(token_ids[i]) == msg.sender,
                "CarvProtocolService: not owner"
            );
            require(
                _verifier_delegate_addresss_map[msg.sender][token_ids[i]] !=
                    address(0),
                "has not ben been deplegtade yet"
            );
            address old_delegated_address = _verifier_delegate_addresss_map[
                msg.sender
            ][token_ids[i]];

            _verifier_weight_changed(
                old_delegated_address,
                target_address_arr[i]
            );
            _verifier_delegate_addresss_map[msg.sender][
                token_ids[i]
            ] = target_address_arr[i];
        }
    }

    /**
        @notice verifier_undelegate
     */
    function verifier_undelegate(uint256[] calldata token_ids) external {
        // TODO 1 change to gas less
        // TODO 2 one day limit check
        for (uint256 i = 0; i < token_ids.length; i++) {
            require(
                _verifier_delegate_addresss_map[msg.sender][token_ids[i]] !=
                    address(0),
                "has not ben been deplegtade yet"
            );
            address old_delegated_address = _verifier_delegate_addresss_map[
                msg.sender
            ][token_ids[i]];

            _verifier_weight_changed(old_delegated_address, msg.sender);
            _verifier_delegate_addresss_map[msg.sender][token_ids[i]] = address(
                0
            );
        }
    }

    /**
        @notice verifier_undelegate
     */
    function _verifier_weight_changed(address from, address to) internal {
        address_vote_weight[from]--;
        address_vote_weight[to]++;
        emit VerifierWeightChanged(from, to);
    }
}
