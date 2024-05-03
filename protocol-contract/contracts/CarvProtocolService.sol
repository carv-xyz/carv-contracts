// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "./ERC7231.sol";
import "./interfaces/ICarvProtocolNFT.sol";
import "./interfaces/ICarvVault.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CarvProtocolService is ERC7231, AccessControlUpgradeable {
    address public vault_address;
    address private _admin_address;

    bytes32 public constant TEE_ROLE = keccak256("TEE_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant MINETR_ROLE = keccak256("MINETR_ROLE");

    uint private _carv_id;
    string private _campaign_id;
    string private _campaign_info;

    bytes32[] public attestation_id_list;
    address[] public verifier_list;
    address public vrf_address;
    address public nft_address;
    uint256 public verifier_pass_threshold;
    uint256 private _cur_token_id;

    struct reward {
        string campaign_id;
        address user_address;
        uint256 reward_amount;
        uint256 total_num;
        address contract_address; // e.g, if token is eth, contract_address is 0x0
        uint8 contract_type; // e.g, native token(eth,bnb...), erc20, erc721...
    }

    struct campaign {
        string campaign_id;
        string url;
        address creator;
        uint8 campaign_type;
        address reward_contract;
        uint256 reward_total_amount;
        uint256 reward_count;
        uint8 status;
        uint256 start_time; // timestamp
        uint256 end_time;
        string requirements;
    }

    struct user {
        uint256 token_id;
        string user_profile_path;
        uint256 profile_version;
        bytes signature;
    }

    struct teeInfo {
        string publicKey;
        string mrEnclave;
    }

    mapping(string => reward) public campain_reward_map;
    mapping(string => campaign) public id_campaign_map;
    // _cur_token_id => campain_id => rawstring
    mapping(uint256 => mapping(string => string)) private _user_campaign_map;

    mapping(address => user) public address_user_map;
    // address => campain_id => proof
    mapping(address => mapping(string => string)) private _proof_campaign_map;

    // attestation_id => verifier_address => result
    mapping(bytes32 => bool) public attestation_id_result_map;
    mapping(bytes32 => address[]) private _attestation_id_verifiers_map;
    mapping(bytes32 => uint256) private _attestation_id_reward_map;
    mapping(address => teeInfo) public addressTeeInfo;

    // verifier block
    mapping(address => uint256) public verifier_block;
    // owner -> tokenId -> receiver
    mapping(address => mapping(uint256 => address))
        private _verifier_delegate_addresss_map;
    mapping(address => uint256) public address_vote_weight;

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

    event SubmitCampaign(
        address contract_address,
        string campaign_id,
        string requirements
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

    event Minted(address to, uint256 token_id);
    event VerifierWeightChanged(address from, address to);

    /**
        @notice Initializes CampaignsService, creates and grants {msg.sender} the admin role,
     */
    function __CarvProtocolService_init(
        address rewards_address,
        address _nft_address
    ) public initializer {
        _admin_address = msg.sender;
        vault_address = rewards_address;
        nft_address = _nft_address;
        _cur_token_id = 1;

        super._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setTeeInfo(
        string calldata publicKey,
        string calldata mrEnclave
    ) external only_tees {
        addressTeeInfo[msg.sender].publicKey = publicKey;
        addressTeeInfo[msg.sender].mrEnclave = mrEnclave;
    }

    /**
        @notice set_pay_address
     */
    function set_vault_address(address _vault_address) external only_admin {
        vault_address = _vault_address;
    }

    /**
        @notice get_verifier_list
     */
    function set_vrf_address(address _vrf_address) external only_admin {
        vrf_address = _vrf_address;
    }

    /**
        @notice set_nft_address
     */
    function set_nft_address(address _nft_address) external only_admin {
        nft_address = _nft_address;
    }

    /**
        @notice set_verifier_pass_threshold
     */
    function set_verifier_pass_threshold(
        uint256 _verifier_pass_threshold
    ) external only_admin {
        verifier_pass_threshold = _verifier_pass_threshold;
    }

    /**
        @notice add_tee_role
     */
    function add_tee_role(address tee_address) external only_admin {
        _setupRole(TEE_ROLE, tee_address);
    }

    /**
     * @notice get_attestation_id_list  the campaign infomation
     */
    function get_proof_list() external view returns (bytes32[] memory) {
        //validate the param
        return attestation_id_list;
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
    ) external payable {
        pay_reward(reward_info, msg.sender);

        //save data
        id_campaign_map[campaign_info.campaign_id] = campaign_info;
        campain_reward_map[reward_info.campaign_id] = reward_info;

        emit SubmitCampaign(
            reward_info.contract_address,
            campaign_info.campaign_id,
            campaign_info.requirements
        );
    }

    /**
        @notice Used to gain custody of deposited token.
        @param reward_info Address of ERC20 to transfer.
        @param owner Address of current token owner.
     */
    function pay_reward(reward calldata reward_info, address owner) internal {
        if (reward_info.contract_type == 0) {
            // native token
            payable(_admin_address).transfer(reward_info.reward_amount);
        } else if (reward_info.contract_type == 1) {
            // erc20
            IERC20(reward_info.contract_address).transferFrom(
                owner,
                _admin_address,
                reward_info.reward_amount
            );
        }

        emit RewardPayed(
            reward_info.contract_address,
            owner,
            _admin_address,
            reward_info.reward_amount
        );
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

        setIdentitiesRoot(
            address_user_map[user_address].token_id,
            multiIdentitiesRoot
        );
    }

    /**
     * @notice join_campaign  the campaign infomation
       @param carv_id carv_id for use nft asset
       @param campaign_id campaign_id for use join
       @param join_campaign_info join_campaign_info t emit
     */
    function join_campaign(
        uint carv_id,
        string calldata campaign_id,
        string calldata join_campaign_info
    ) external {
        _carv_id = carv_id;
        _campaign_id = campaign_id;
        _campaign_info = join_campaign_info;

        emit UserCampaignData(_carv_id, _campaign_id, _campaign_info);
    }

    /**
     * @notice report_tee_attestation  the campaign infomation
     */
    function report_tee_attestation(
        string calldata campaign_id,
        string calldata attestation
    ) external only_tees {
        bytes32 attestation_id = keccak256(bytes(attestation));
        attestation_id_list.push(attestation_id);
        uint256 reward_amount = campain_reward_map[campaign_id].reward_amount;

        _attestation_id_reward_map[attestation_id] = reward_amount;

        emit ReportTeeAttestation(
            msg.sender,
            campaign_id,
            attestation_id,
            attestation
        );
    }

    function verify_attestation(bytes32 attestation_id, bool result) external {
        require(
            address_vote_weight[msg.sender] > 0,
            "CarvProtocolService: no vote weight"
        );

        require(
            _is_exit_in_attestation_list(attestation_id),
            "attestation is not exist"
        );
        require(
            !_is_verified_by_same_verifier(attestation_id),
            "attestation can not by verify again"
        );

        _attestation_id_verifiers_map[attestation_id].push(msg.sender);
        if (_is_verifer_sign_enough(attestation_id) && result) {
            pay_platform_profit();
            attestation_id_result_map[attestation_id] = result;
        }

        require(
            verifier_block[msg.sender] < block.number,
            "CarvProtocolService: verifier block is invalid"
        );

        verifier_block[msg.sender] = block.number;

        emit VerifyAttestation(msg.sender, attestation_id, result);
    }

    function verify_attestation_batch(
        bytes32[] calldata attestation_ids,
        bool[] calldata results
    ) external {
        require(
            ICarvProtocolNFT(nft_address).address_vote_weight(msg.sender) > 0,
            "CarvProtocolService: no vote weight"
        );

        uint256 nLen = attestation_ids.length;
        for (uint256 i = 0; i < nLen; i++) {
            require(
                _is_exit_in_attestation_list(attestation_ids[i]),
                "attestation is not exist"
            );
            attestation_id_result_map[attestation_ids[i]] = results[i];
            _attestation_id_verifiers_map[attestation_ids[i]].push(msg.sender);
            if (_is_verifer_sign_enough(attestation_ids[i])) {
                pay_platform_profit();
                attestation_id_result_map[attestation_ids[i]] = results[i];
            }
        }

        emit VerifyAttestationBatch(msg.sender, attestation_ids, results);
    }

    /**
        @notice mint
     */
    function mint(address _to) external {
        // TODO 1 change to gas less
        // TODO 2 one day limit check
        ICarvProtocolNFT(nft_address).mint(_to, _cur_token_id);

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
                ICarvProtocolNFT(nft_address).ownerOf(token_ids[i]) ==
                    msg.sender,
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
                ICarvProtocolNFT(nft_address).ownerOf(token_ids[i]) ==
                    msg.sender,
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
                ICarvProtocolNFT(nft_address).ownerOf(token_ids[i]) ==
                    msg.sender,
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

            _verifier_weight_changed(old_delegated_address, msg.sender);
            _verifier_delegate_addresss_map[msg.sender][token_ids[i]] = address(
                0
            );
        }
    }

    // ================== internal functions ==================

    function pay_platform_profit() internal {
        uint256 profitAmount = ICarvVault(vault_address).getServiceProfit(
            msg.sender
        );

        ICarvVault(vault_address).withdrawProfit(msg.sender);

        emit ProfixPayed(
            vault_address,
            _admin_address,
            msg.sender,
            profitAmount
        );
    }

    function _is_verified_by_same_verifier(
        bytes32 attestation_id
    ) internal view returns (bool) {
        address[]
            memory _verifier_attestation_list = _attestation_id_verifiers_map[
                attestation_id
            ];
        uint len = _verifier_attestation_list.length;

        for (uint i = 0; i < len; i++) {
            if (_verifier_attestation_list[i] == msg.sender) {
                return true;
            }
        }

        return false;
    }

    function _is_verifer_sign_enough(
        bytes32 attestation_id
    ) internal view returns (bool) {
        // TODO add vote weight logic
        uint256 total_sign = _attestation_id_verifiers_map[attestation_id]
            .length;
        if (total_sign >= verifier_pass_threshold) {
            return true;
        }

        return false;
    }

    function _is_exit_in_attestation_list(
        bytes32 attestation_id
    ) internal view returns (bool) {
        for (uint256 i = 0; i < attestation_id_list.length; i++) {
            if (attestation_id_list[i] == attestation_id) {
                return true;
            }
        }

        return false;
    }

    /**
        @notice verifier_undelegate
     */
    function _verifier_weight_changed(address from, address to) internal {
        address_vote_weight[from]--;
        address_vote_weight[to]++;
        emit VerifierWeightChanged(from, to);
    }

    // ================== override functions ==================
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC7231, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
