// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "./ERC7231.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";
contract CarvProtocalService is ERC7231,AccessControlUpgradeable{

    address private _rewards_address;
    address private _admin_address;

    bytes32 public constant TEE_ROLE = keccak256("TEE_ROLE");
    // Verifier
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    uint256 private _cur_token_id;
    mapping(uint256 => string) private _id_uri_map;
    mapping(address=>uint256) private _addresd_id_map;

    uint private _carv_id;
    string private _campaign_id;
    string private _campaign_info;

    struct reward {
        string campaign_id;
        address user_address;
        uint256 reward_amount;
        uint256 total_num;
        address contract_address;
        uint8 contract_type; // e.g, erc20, erc721...
    }

    struct campaign {
        string  campaign_id;
        string url;
        address creator;
        uint8   campaign_type;
        address reward_contract;
        uint256 reward_total_amount;
        uint256 reward_count; 
        uint8   status;
        uint256 start_time;// timestamp
        uint256 end_time;
        string  requirements;
    }

    struct user {
        uint256 token_id;
        string  user_profile_path;
        uint256 profile_version;
        bytes signature;
    }

    mapping(string => reward)  private campain_reward_map;
    mapping(string => campaign) private id_campaign_map;
    // _cur_token_id => campain_id => rawstring
    mapping( uint256 => mapping(string => string)) private _user_campaign_map;

    mapping(address => user) private address_user_map;
    // address => campain_id => proof
    mapping(address => mapping(string => string)) private _proof_campaign_map;

    // attestation_id => verifier_address => result
    mapping(bytes32 => mapping(address => bool)) private _attestation_id_verifier_result_map;

    bytes32[] _attestation_id_list;

    modifier only_admin() {
        _only_admin();
        _;
    }

    modifier only_tees() {
        _only_tees();
        _;
    }

    modifier only_verifiers(){
        _only_verifiers();
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

    function _only_verifiers() private view {
        require(hasRole(VERIFIER_ROLE, msg.sender), "sender doesn't have verifier role");
    }

    event SubmitCampaign(
        address contract_address,
        string  campaign_id,
        string  requirements
    );

    event RewardPayed(
        address erc20_address,
        address from_address,
        address to_address,
        uint256 amount
    );

    event Minted(
        address to,
        uint256 token_id
    );

    //
    event UserCampaignData(
        uint carv_id, 
        string campaign_id, 
        string campaign_info
    );

    event ReportTeeAttestation(
        address tee_address,
        string campaign_id,
        bytes32 attestation_id,
        string attestation
    );

    event VerifyAttestation(
        address verifier_address,
        bytes32 attestation_id,
        bool result
    );

    event VerifyAttestationBatch(
        address verifier_address,
        bytes32[] attestation_ids,
        bool[] results
    );

    /**
        @notice Initializes CampaignsService, creates and grants {msg.sender} the admin role,
     */
    function __CarvProtocalService_init(
        address rewards_address
    ) public initializer{
        _admin_address = msg.sender;
        _rewards_address = rewards_address;
        _cur_token_id = 1;

        super._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC7231, AccessControlUpgradeable) returns (bool) {
            return super.supportsInterface(interfaceId);
    }

    /**
        @notice add_tee_role
     */
    function add_tee_role(address tee_address) external only_admin {
        _setupRole(TEE_ROLE, tee_address);
    }

    /**
        @notice add_verifier_role
     */
    function add_verifier_role(address verifier_address) external only_admin {
        _setupRole(VERIFIER_ROLE, verifier_address);
    }

    /**
        @notice Used to gain custody of deposited token.
        @param reward_info Address of ERC20 to transfer.
        @param campaign_info Amount of tokens to transfer.
     */
    // check CampaignsStatus
    function submit_campaign(
        reward calldata reward_info,
        campaign calldata campaign_info
    ) external payable{

        pay_reward(reward_info,msg.sender);

        //save data
        id_campaign_map[campaign_info.campaign_id] = campaign_info;
        campain_reward_map[reward_info.campaign_id] = reward_info;

        emit SubmitCampaign(reward_info.contract_address,campaign_info.campaign_id,campaign_info.requirements);
    }

    /**
        @notice Used to gain custody of deposited token.
        @param reward_info Address of ERC20 to transfer.
        @param owner Address of current token owner.
     */
    function pay_reward(reward calldata reward_info,address owner) internal {

        IERC20 erc20 = IERC20(reward_info.contract_address);
        _safeTransferFrom(erc20, owner, _admin_address, reward_info.reward_amount);
   
        emit RewardPayed(reward_info.contract_address, owner, _admin_address, reward_info.reward_amount);

    }


    /**
        @notice used to transfer ERC20s safely
        @param token Token instance to transfer
        @param from Address to transfer token from
        @param to Address to transfer token to
        @param value Amount of token to transfer
     */
    function _safeTransferFrom(IERC20 token, address from, address to, uint256 value) private {
        _safeCall(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
        @notice used to make calls to ERC20s safely
        @param token Token instance call targets
        @param data encoded call data
     */
    function _safeCall(IERC20 token, bytes memory data) private {
        uint256 tokenSize;
        assembly {
            tokenSize := extcodesize(token)
        }         
        require(tokenSize > 0, "ERC20: not a contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "ERC20: call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "ERC20: operation did not succeed");
        }
    }

    /**
        @notice mint CompaignsService, creates and grants {msg.sender} the admin role,
        @param to Address to transfer token to
        @param uri uri for nft asset
     */
    // only Auth/Admin can access
    function mint(address to,string memory uri) external{

        require(balanceOf(to) == 0,"duplicate mint exception");

        _mint(to,_cur_token_id);
        _id_uri_map[_cur_token_id] = uri;
        
        _addresd_id_map[to] = _cur_token_id;
        emit Minted(to,_cur_token_id);

        _cur_token_id ++ ;

    }

    /**
     * @notice get_user_by_address  the campaign infomation
       @param user_address use address for nft
     */
    function get_mint_by_address(
        address user_address
    ) external view returns (string memory) {
        //validate the param
        uint256 id = _addresd_id_map[user_address];
        return _id_uri_map[id];
    }

    /**
        @notice set_identities_root
     */
    // and check profile version
    function set_identities_root(
        address user_address,
        string calldata user_profile_path,
        uint256 profile_version,
        bytes32 multiIdentitiesRoot,
        bytes calldata signature
    ) external {

        address_user_map[user_address].user_profile_path = user_profile_path;
        address_user_map[user_address].profile_version = profile_version;
        address_user_map[user_address].signature = signature;

        setIdentitiesRoot(address_user_map[user_address].token_id,multiIdentitiesRoot);

    }

    /**
     * @notice get_user_by_address  the campaign infomation
       @param user_address use address for nft
     */
    function get_user_by_address(
        address user_address
    ) external view returns (user memory) {
        //validate the param
        return address_user_map[user_address];
    }

    /**
     * @notice join_campaign  the campaign infomation
       @param carv_id carv_id for use nft asset
       @param campaign_id campaign_id for use join
       @param join_campaign_info join_campaign_info t emit
     */
    function join_campaign(uint carv_id, string calldata campaign_id, string calldata join_campaign_info) external {
        _carv_id = carv_id;
        _campaign_id = campaign_id;
        _campaign_info = join_campaign_info;

        emit UserCampaignData(_carv_id, _campaign_id, _campaign_info);
    }

    // /**
    //  * @notice verify_campaign_user  the campaign infomation
    //  */
    // function verify_campaign_user(address user_address,string calldata campaign_id,string calldata proof) external payable only_tees{ 
    //     reward memory reward_info = campain_reward_map[campaign_id];
        
    //     IERC20 erc20 = IERC20(reward_info.contract_address);
    //     uint amount = reward_info.reward_amount / reward_info.total_num;
        
    //     _safeTransferFrom(erc20, _admin_address, user_address, amount);
    //     _proof_campaign_map[user_address][campaign_id] = proof;

    //     emit RewardPayed(reward_info.contract_address, _admin_address, user_address, reward_info.reward_amount);
    // }

    /**
     * @notice report_tee_attestation  the campaign infomation
     */
    function report_tee_attestation(string calldata campaign_id,string calldata attestation) external only_tees{ 

        bytes32 attestation_id = keccak256(bytes(attestation));

        _attestation_id_list.push(attestation_id);
        emit ReportTeeAttestation(msg.sender,campaign_id,attestation_id,attestation);

    }

   function verify_attestation(bytes32 attestation_id,bool result)external only_verifiers{ 

        require(_is_exit_in_attestation_list(attestation_id),"attestation is not exist");

        _attestation_id_verifier_result_map[attestation_id][msg.sender] = result;
        emit VerifyAttestation(msg.sender,attestation_id,result);
   }


   function verify_attestation_batch(bytes32[] calldata attestation_ids,bool[] calldata results)external only_verifiers{

        uint256 nLen = attestation_ids.length;
        for(uint256 i = 0 ;i < nLen ;i ++){

            require(_is_exit_in_attestation_list(attestation_ids[i]),"attestation is not exist");
            _attestation_id_verifier_result_map[attestation_ids[i]][msg.sender] = results[i];
        }

        emit VerifyAttestationBatch(msg.sender,attestation_ids,results);
   }


   function _is_exit_in_attestation_list(bytes32 attestation_id) view internal returns(bool){

        for(uint256 i = 0 ;i < _attestation_id_list.length ;i ++ ){

            if(_attestation_id_list[i] == attestation_id){
                return true;
            }
        }

        return false;

   }

    /**
     * @notice get_user_by_address  the campaign infomation
     */
    function get_proof_list(
    ) external view returns (bytes32[] memory) {
        //validate the param
        return _attestation_id_list;
    }

    /**
     * @notice get_user_by_address  the campaign infomation
     */
    function get_attestation_result(
        bytes32 attestation_id,
        address attestation_address
    ) external view returns (bool) {

       return _attestation_id_verifier_result_map[attestation_id][attestation_address];
    }


}
