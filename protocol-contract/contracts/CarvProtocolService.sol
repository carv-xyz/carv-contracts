// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "./ERC7231.sol";
import "./CarvProtocolNFT.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "hardhat/console.sol";

contract CarvProtocolService is ERC7231,AccessControlUpgradeable{

    address private _rewards_address;
    address private _admin_address;

    bytes32 public constant TEE_ROLE = keccak256("TEE_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    uint256 private _cur_token_id;
    mapping(uint256 => string) private _id_uri_map;
    mapping(address=>uint256) private _addresd_id_map;

    uint    private _carv_id;
    string  private _campaign_id;
    string  private _campaign_info;
    address private _pay_address;

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
        string  url;
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
        bytes   signature;
    }

    mapping(string => reward)  private _campain_reward_map;
    mapping(string => campaign) private _id_campaign_map;
    // _cur_token_id => campain_id => rawstring
    mapping( uint256 => mapping(string => string)) private _user_campaign_map;

    mapping(address => user) private _address_user_map;
    // address => campain_id => proof
    mapping(address => mapping(string => string)) private _proof_campaign_map;

    // attestation_id => verifier_address => result
    mapping(bytes32 => bool) private _attestation_id_result_map;
    mapping(bytes32 => address[]) private _attestation_id_verifiers_map;
    mapping(bytes32 => uint256) private _attestation_id_reward_map;

    bytes32[] _attestation_id_list;
    address[] _verifier_list;
    address _vrf_address;
    address _nft_address;
    uint256 _verifier_pass_threshold;
   mapping(address => uint256) private _address_vote_weight;
   
    struct teeInfo{
        string publicKey;
        string mrEnclave;
    }
    mapping(address => teeInfo) _addressTeeInfo;
    mapping(address => address) private _verifier_delegate_addresss_map;

    struct openVerifierNodeData {
        address account;
        uint256 token_id;
        uint256 timestamp;
    }

    struct mintData {
        address account;
        uint256 timestamp;
    }

    struct delegateData {
        address from;
        address to;
        uint256 timestamp;
    }

    uint constant private DAY_IN_SECONDS = 86400;
    uint256 CHAIN_ID = uint256(block.chainid);
    bytes32 EIP712_DOMAIN_HASH = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId)"
            ),
            keccak256(bytes("CarvProtocolService")),
            keccak256(bytes("1")),
            CHAIN_ID
        )
    );

    mapping(uint256 => bool) _verifier_node_is_open_map;

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
        require( 
            CarvProtocolNFT(_nft_address).balanceOf(msg.sender) > 0 || 
            hasRole(VERIFIER_ROLE, msg.sender), "sender doesn't have verifier role"
        );
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

    event ProfixPayed(
        address erc20_address,
        address from_address,
        address to_address,
        uint256 amount
    );

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

    event Minted(
        address to,
        uint256 token_id
    );

    event VerifierWeightChanged(
        address from,
        address to
    );

    event OpenVerifierNode(
        address account,
        uint256 token_id,
        uint256 timestamp
    );

    event RecoverParams(
        uint256 chainId,
        bytes32 eip712DomainHash,
        bytes32 hashStruct,
        bytes32 digest
    );

    /**
        @notice Initializes CampaignsService, creates and grants {msg.sender} the admin role,
     */
    function __CarvProtocolService_init(
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

    function setTeeInfo(string calldata publicKey,string calldata mrEnclave)external only_tees{

            _addressTeeInfo[msg.sender].publicKey = publicKey;
            _addressTeeInfo[msg.sender].mrEnclave = mrEnclave;
    }

    function getTeeInfo(address teeAddress)external view returns(string memory,string memory){

        return (_addressTeeInfo[teeAddress].publicKey,_addressTeeInfo[teeAddress].mrEnclave);
    }
    
    /**
        @notice add_tee_role
     */
    function add_tee_role(address tee_address) external only_admin {
        _setupRole(TEE_ROLE, tee_address);
    }

    /**
        @notice set_pay_address
     */
    function set_pay_address(address pay_address) external only_admin {
        _pay_address = pay_address;
    }

    /**
        @notice get_pay_address
     */
    function get_pay_address() external view returns(address) {
        return _pay_address;
    }

    /**
        @notice get_verifier_list
     */
    function get_verifier_list() external view returns(address[] memory) {
        return _verifier_list;
    }

    /**
        @notice set_vrf_address
     */
    function set_vrf_address(address vrf_address) external only_admin{
        _vrf_address = vrf_address;
    }

    /**
        @notice get_vrf_address
     */
    function get_vrf_address() external view returns(address) {
        return _vrf_address;
    }

    /**
        @notice set_nft_address
     */
    function set_nft_address(address nft_address) external only_admin {
        _nft_address = nft_address;
    }

    /**
        @notice get_pay_address
     */
    function get_nft_address() external view returns(address) {
        return _nft_address;
    }

    /**
        @notice set_verifier_pass_threshold
     */
    function set_verifier_pass_threshold(uint256 verifier_pass_threshold) external only_admin {
        _verifier_pass_threshold = verifier_pass_threshold;
    }

    /**
        @notice get_verifier_pass_threshold
     */
    function get_verifier_pass_threshold() external view returns(uint256) {
        return _verifier_pass_threshold;
    }


    /**
        @notice add_verifier_role
     */
    function add_verifier_role(address verifier_address) external only_admin {

         _verifier_list.push(verifier_address);
        _setupRole(VERIFIER_ROLE, verifier_address);

    }

    /**
        @notice mint
     */
    function mint(mintData calldata mint_data, bytes memory signature) external {
   
        // make sure signature is valid and get the address of the signer
        address _signer = _mint_recover(mint_data, signature);
        require(_signer == mint_data.account, "verify the signature failed");
       
        // make sure run once a day
        require(block.timestamp >= mint_data.timestamp +  DAY_IN_SECONDS, "can only be sumbited once a day");
     
        CarvProtocolNFT(_nft_address).mint(mint_data.account,_cur_token_id);

        _address_vote_weight[mint_data.account] ++  ;
        _cur_token_id ++ ;

        emit Minted(mint_data.account,_cur_token_id);

    }


    /**
    * @notice Verifies the signature for a given token_id, returning the address of the signer.
    * @param data token id of the given nft.
    */
    function _mint_recover(mintData calldata data, bytes memory signature) internal returns (address) {

    
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("mintData(address account,uint256 timestamp)"),
                data.account,
                data.timestamp
            )
        );

        return _get_recover_address(hashStruct,signature);
    }

    /**
        @notice verifier_delegate
     */
    function verifier_delegate(delegateData calldata delegate_data, bytes memory signature) external {

        // make sure signature is valid and get the address of the signer
        address _signer = _delegate_recover(delegate_data, signature);
        require(_signer == delegate_data.from, "verify the signature failed");
       
        // make sure run once a day
        require(block.timestamp >= delegate_data.timestamp +  DAY_IN_SECONDS, "can only be sumbited once a day");
   

        require( _verifier_delegate_addresss_map[delegate_data.from] == address(0),"already been delegated");

        _verifier_weight_changed(delegate_data.from,delegate_data.to);
        _verifier_delegate_addresss_map[delegate_data.from] = delegate_data.to;
    }


    /**
        @notice verifier_redelegate
     */
    function verifier_redelegate(delegateData calldata delegate_data, bytes memory signature) public {

        // make sure signature is valid and get the address of the signer
        address _signer = _delegate_recover(delegate_data, signature);
        require(_signer == delegate_data.from, "verify the signature failed");
       
        // make sure run once a day
        require(block.timestamp >= delegate_data.timestamp +  DAY_IN_SECONDS, "can only be sumbited once a day");
   
        address old_delegated_address =_verifier_delegate_addresss_map[delegate_data.from];
        
        _verifier_weight_changed(old_delegated_address,delegate_data.to);
        _verifier_delegate_addresss_map[delegate_data.from] = delegate_data.to;
    }

    /**
        @notice verifier_undelegate
     */
    function verifier_undelegate(delegateData calldata delegate_data, bytes memory signature) external {

        // make sure signature is valid and get the address of the signer
        address _signer = _delegate_recover(delegate_data, signature);
        require(_signer == delegate_data.from, "verify the signature failed");
       
        // make sure run once a day
        require(block.timestamp >= delegate_data.timestamp +  DAY_IN_SECONDS, "can only be sumbited once a day");
   

        address old_delegated_address =_verifier_delegate_addresss_map[delegate_data.from];
        
        _verifier_weight_changed(old_delegated_address,delegate_data.from);
        _verifier_delegate_addresss_map[delegate_data.from] = address(0);
    }

    /**
    * @notice Verifies the signature for a given token_id, returning the address of the signer.
    * @param data token id of the given nft.
    */
    function _delegate_recover(delegateData calldata data, bytes memory signature) internal returns (address) {

    
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("delegateData(address from,address to,uint256 timestamp)"),
                data.from,
                data.to,
                data.timestamp
            )
        );

        return _get_recover_address(hashStruct,signature);
    }

    /**
        @notice verifier_undelegate
     */
    function _verifier_weight_changed(address from,address to) internal {

        _address_vote_weight[from] --  ;
        _address_vote_weight[to] ++ ;

        emit VerifierWeightChanged(from,to);
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
        _id_campaign_map[campaign_info.campaign_id] = campaign_info;
        _campain_reward_map[reward_info.campaign_id] = reward_info;

        emit SubmitCampaign(reward_info.contract_address,campaign_info.campaign_id,campaign_info.requirements);
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

        _address_user_map[user_address].user_profile_path = user_profile_path;
        _address_user_map[user_address].profile_version = profile_version;
        _address_user_map[user_address].signature = signature;

        setIdentitiesRoot(_address_user_map[user_address].token_id,multiIdentitiesRoot);

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
     * @notice get_user_by_address  the campaign infomation
       @param user_address use address for nft
     */
    function get_user_by_address(
        address user_address
    ) external view returns (user memory) {
        //validate the param
        return _address_user_map[user_address];
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

    /**
     * @notice report_tee_attestation  the campaign infomation
     */
    function report_tee_attestation(string calldata campaign_id,string calldata attestation) external only_tees{ 

        bytes32 attestation_id = keccak256(bytes(attestation));
        _attestation_id_list.push(attestation_id);
        uint256 reward_amount = _campain_reward_map[campaign_id].reward_amount;

        _attestation_id_reward_map[attestation_id] = reward_amount;

        emit ReportTeeAttestation(msg.sender,campaign_id,attestation_id,attestation);

    }

   function verify_attestation(bytes32 attestation_id,bool result)external only_verifiers{ 

        require(_is_exit_in_attestation_list(attestation_id),"attestation is not exist");
        require(!_is_verified_by_same_verifier(attestation_id),"attestation can not by verify again");

        _attestation_id_verifiers_map[attestation_id].push(msg.sender);
        if(_is_verifer_sign_enough(attestation_id) && result){
            pay_profit(attestation_id);
            _attestation_id_result_map[attestation_id] = result;
        }

        emit VerifyAttestation(msg.sender,attestation_id,result);
   }

   function verify_attestation_batch(bytes32[] calldata attestation_ids,bool[] calldata results)external only_verifiers{

        uint256 nLen = attestation_ids.length;
        for(uint256 i = 0 ;i < nLen ;i ++){

            require(_is_exit_in_attestation_list(attestation_ids[i]),"attestation is not exist");
            _attestation_id_result_map[attestation_ids[i]] = results[i];
            _attestation_id_verifiers_map[attestation_ids[i]].push(msg.sender);
            if(_is_verifer_sign_enough(attestation_ids[i]) ){
                pay_profit(attestation_ids[i]);
                _attestation_id_result_map[attestation_ids[i]] = results[i];
            }
        }

        emit VerifyAttestationBatch(msg.sender,attestation_ids,results);
   }

    function pay_profit(bytes32 attestation_id) internal {

        IERC20 erc20 = IERC20(_pay_address);
        _safeTransferFrom(erc20, _admin_address, msg.sender, _attestation_id_reward_map[attestation_id]);
        emit ProfixPayed(_pay_address,_admin_address, msg.sender, _attestation_id_reward_map[attestation_id]);

    }

   function _is_verified_by_same_verifier(bytes32 attestation_id) internal view returns(bool){

        address[] memory _verifier_attestation_list = _attestation_id_verifiers_map[attestation_id];
        uint len = _verifier_attestation_list.length;

        for(uint i = 0 ;i < len ;i ++ ){
            if(_verifier_attestation_list[i] == msg.sender){
                return true;
            }
        }
    
        return false;
   }

   function _is_verifer_sign_enough(bytes32 attestation_id) internal pure returns(bool){

        // TODO add vote weight logic
        return false;
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
        bytes32 attestation_id
    ) external view returns (bool) {

       return _attestation_id_result_map[attestation_id];
    }


    /**
    * @notice open_verifier_node  
    */
    function open_verifier_node(openVerifierNodeData calldata verifier_data, bytes memory signature)external {

        // make sure signature is valid and get the address of the signer
        address _signer = _open_verifier_node_recover(verifier_data, signature);
        address _nft_owner = CarvProtocolNFT(_nft_address).ownerOf(verifier_data.token_id);
        require(_signer == verifier_data.account, "verify the signature failed");
        require(_signer == _nft_owner, "verify the nft owner failed");

        // make sure run once a day
        require(block.timestamp >= verifier_data.timestamp +  DAY_IN_SECONDS, "can only be sumbited once a day");

        // recode the verifier open status
        _verifier_node_is_open_map[verifier_data.token_id] = true;

        // emit the open verifier node event
        emit OpenVerifierNode(verifier_data.account,verifier_data.token_id,verifier_data.timestamp);
    }

    /**
    * @notice Verifies the signature for a given token_id, returning the address of the signer.
    * @param data token id of the given nft.
    */
    function _open_verifier_node_recover(openVerifierNodeData calldata data, bytes memory signature) internal returns (address) {

    
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("openVerifierNodeData(address account,uint256 token_id,uint256 timestamp)"),
                data.account,
                data.token_id,
                data.timestamp
            )
        );

        return _get_recover_address(hashStruct,signature);
  
    }


    /**
    * @notice Verifies the signature for a given token_id, returning the address of the signer.
    * @param hashStruct token id of the given nft.
    */
    function _get_recover_address(bytes32 hashStruct,bytes memory signature) internal returns (address) {

    
        // 1. hashing the data (above is part of this) and generating the hashes 
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", EIP712_DOMAIN_HASH, hashStruct));
        emit RecoverParams(CHAIN_ID,EIP712_DOMAIN_HASH,hashStruct,digest);

        return ECDSAUpgradeable.recover(digest, signature);
    }


    /**
    * @notice close_verifier_node  
    */
    function close_verifier_node(openVerifierNodeData calldata verifier_data)external {

    }


}
