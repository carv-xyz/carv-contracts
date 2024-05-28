// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

pragma experimental ABIEncoderV2;
import "./ERC7231.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "hardhat/console.sol";
contract CarvID is ERC7231,OwnableUpgradeable,AccessControlUpgradeable{

    uint256 private _cur_token_id;
    string private _version;

    struct user {
        uint256 token_id;
        string  user_profile_path;
        uint256 profile_version;
        bytes signature;
    }

    event Minted(
        address to,
        uint256 token_id
    );

    bytes32 public constant TEE_ROLE = keccak256("TEE_ROLE");
    mapping(address => user) private address_user_map;
    event AdminTrasnferd(address oldAdmin,address newAdmin);

    modifier only_admin() {
        _only_admin();
        _;
    }

    modifier only_tees() {
        _only_tees();
        _;
    }

    function _only_admin() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "sender doesn't have admin role"
        );
    }

    function _only_tees() private view {
        require(hasRole(TEE_ROLE, msg.sender), "sender doesn't have tee role");
    }

    /**
        @notice Initializes CompaignsService, creates and grants {msg.sender} the admin role,
     */
    function __CarvID_init(string calldata version,string calldata name,string calldata symbol) public initializer {

        _version = version;
        _cur_token_id = 1;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __ERC7231_init(name, symbol);

    
    }

    /**
        @notice transfer_admin,
     */
    function transfer_admin(address new_admin_address) external only_admin {
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, new_admin_address);

        emit AdminTrasnferd(msg.sender, new_admin_address);
    }

    /**
        @notice is_admin,
     */
    function is_admin(address check_address) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, check_address);
    }

    /**
        @notice add_tee_role
     */
    function add_tee_role(address tee_address) external only_admin {
        _setupRole(TEE_ROLE, tee_address);
    }


    /**
        @notice mint CompaignsService, creates and grants {msg.sender} the admin role,
     */
    // only Auth/Admin can access
    function mint() external{

        require(balanceOf(msg.sender) == 0,"duplicate mint exception");

        _mint(msg.sender,_cur_token_id);
        emit Minted(msg.sender,_cur_token_id);

        address_user_map[msg.sender].token_id = _cur_token_id;
        address_user_map[msg.sender].user_profile_path = "";
        address_user_map[msg.sender].profile_version = 0;
        _cur_token_id ++ ;
    }

    /**
     * @notice get_user_by_address  the campaign infomation
     */
    function get_user_by_address(
        address user_address
    ) external view returns (user memory) {
        //validate the param
        return address_user_map[user_address];
    }

    /**
        @notice update_user_profile
     */
    // and check profile version
    function update_user_profile(
        address user_address,
        address tee_address,
        string calldata user_profile_path,
        uint256 profile_version,
        bytes32 multiIdentitiesRoot,
        string[] calldata userIDs,
        bytes calldata signature
    ) external only_tees {

        require(hasRole(TEE_ROLE, tee_address),"verify identities failed");
    
        bool isVerified = verifyIdentitiesBinding(
            address_user_map[user_address].token_id,
            user_address,
            tee_address,
            userIDs,
            multiIdentitiesRoot,
            signature);

        require(isVerified,"verify identities failed");

        //verify
        address_user_map[user_address].user_profile_path = user_profile_path;
        address_user_map[user_address].profile_version = profile_version;
        address_user_map[user_address].signature = signature;

        setIdentitiesRoot(address_user_map[user_address].token_id,multiIdentitiesRoot);

    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 token_id) public view virtual override returns (string memory) {

        require(address_user_map[msg.sender].token_id == token_id,"token id is not correct");
        return address_user_map[msg.sender].user_profile_path;
    }

    /**
        @notice get_user_profile_by_address user_address
     */
    function get_user_profile_by_address(
        address user_address
    ) external view returns (string memory,uint256) {
        return (address_user_map[user_address].user_profile_path,address_user_map[user_address].profile_version);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {

        revert("do not suppport transferFrom");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("do not suppport safeTransferFrom");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        revert("do not suppport safeTransferFrom");
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC7231, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
