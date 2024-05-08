// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "./ERC7231.sol";
import "./interfaces/ICarvProtocolNFT.sol";
import "./interfaces/ICarvVault.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract CarvProtocolService is ERC7231, AccessControlUpgradeable {
    bytes32 public constant TEE_ROLE = keccak256("TEE_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant PLATFORM_MINETR_ROLE =
        keccak256("PLATFORM_MINETR_ROLE");
    bytes32 public constant FORWARDER_ROLE = keccak256("FORWARDER_ROLE");

    address public vault_address;
    address public _admin_address;

    uint public _carv_id;
    string public _campaign_id;
    string public _campaign_info;

    bytes32[] public attestation_id_list;
    mapping(bytes32 => bool) public attestation_id_map;

    address[] public verifier_list;
    address public vrf_address;
    bytes32[] _attestation_id_list;
    address[] _verifier_list;
    address public nft_address;
    uint256 public verifier_pass_threshold;
    uint256 public _cur_token_id;
    uint256 public nonce;

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

    mapping(address => teeInfo) _addressTeeInfo;

    struct openVerifierNodeData {
        address account;
        uint256 token_id;
        uint256 timestamp;
    }

    struct delegateData {
        address from;
        address to;
        uint256 tokenId;
        uint256 nonce;
        uint256 timestamp;
    }

    uint private constant DAY_IN_SECONDS = 86400;
    uint256 public CHAIN_ID;
    bytes32 public EIP712_DOMAIN_HASH;

    mapping(uint256 => bool) _verifier_node_is_open_map;

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
    function initialize(
        address rewards_address,
        address _nft_address,
        uint256 _chainId
    ) public initializer {
        _admin_address = msg.sender;
        vault_address = rewards_address;
        nft_address = _nft_address;
        _cur_token_id = 1;
        CHAIN_ID = _chainId;
        EIP712_DOMAIN_HASH = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId)"
                ),
                keccak256(bytes("CarvProtocolService")),
                keccak256(bytes("1")),
                CHAIN_ID
            )
        );
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setTeeInfo(
        string calldata publicKey,
        string calldata mrEnclave
    ) external onlyRole(TEE_ROLE) {
        addressTeeInfo[msg.sender].publicKey = publicKey;
        addressTeeInfo[msg.sender].mrEnclave = mrEnclave;
    }

    /**
        @notice set_pay_address
     */
    function set_vault_address(
        address _vault_address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vault_address = _vault_address;
    }

    /**
        @notice get_verifier_list
     */
    function set_vrf_address(
        address _vrf_address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vrf_address = _vrf_address;
    }

    /**
        @notice set_nft_address
     */
    function set_nft_address(
        address _nft_address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nft_address = _nft_address;
    }

    /**
        @notice set_verifier_pass_threshold
     */
    function set_verifier_pass_threshold(
        uint256 _verifier_pass_threshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        verifier_pass_threshold = _verifier_pass_threshold;
    }

    /**
     * @notice get_attestation_id_list  the campaign infomation
     */
    function get_proof_list(
        uint256 startId,
        uint256 endId
    ) external view returns (bytes32[] memory) {
        //validate the param
        bytes32[] memory attestation_id_list_tmp = new bytes32[](
            endId - startId
        );
        for (uint256 i = startId; i < endId; i++) {
            attestation_id_list_tmp[i - startId] = attestation_id_list[i];
        }
        return attestation_id_list_tmp;
    }

    /**
        @notice mint testnet ; 
     */
    //TODO Mainnet must remove;
    function mint(address _to) external {
        ICarvProtocolNFT(nft_address).mint(_to, _cur_token_id);
        address_vote_weight[_to]++;
        emit Minted(_to, _cur_token_id);

        _cur_token_id++;
    }

    /**
        @notice mint
        @param receivers the address of the receiver
     */
    // function mint(
    //     address[] calldata receivers
    // ) external onlyRole(PLATFORM_MINETR_ROLE) {
    //     ICarvProtocolNFT(nft_address).batchMint(receivers, _cur_token_id);
    //     for (uint256 i = 0; i < receivers.length; i++) {
    //         address_vote_weight[receivers[i]]++;
    //         emit Minted(receivers[i], _cur_token_id);
    //         _cur_token_id++;
    //     }
    // }

    /**
        @notice verifier_delegate
     */
    function verifier_delegate(
        delegateData calldata delegate_data,
        bytes memory signature
    ) external onlyRole(FORWARDER_ROLE) {
        require(
            ICarvProtocolNFT(nft_address).ownerOf(delegate_data.tokenId) ==
                delegate_data.from,
            "CarvProtocolService: nft owner is invalid"
        );
        require(
            delegate_data.nonce > nonce,
            "CarvProtocolService: nonce is invalid"
        );
        // make sure signature is valid and get the address of the signer
        address _signer = _delegate_recover(delegate_data, signature);
        require(
            _signer == delegate_data.from,
            "CarvProtocolService: verify the signature failed"
        );

        // make sure run once a day
        // require(
        //     block.timestamp >= delegate_data.timestamp + DAY_IN_SECONDS,
        //     "CarvProtocolService: can only be sumbited once a day"
        // );

        require(
            _verifier_delegate_addresss_map[delegate_data.from][
                delegate_data.tokenId
            ] == address(0),
            "CarvProtocolService: already been delegated"
        );

        _verifier_weight_changed(delegate_data.from, delegate_data.to);
        _verifier_delegate_addresss_map[delegate_data.from][
            delegate_data.tokenId
        ] = delegate_data.to;

        nonce++;

        emit VerifierWeightChanged(delegate_data.from, delegate_data.to);
    }

    /**
        @notice verifier_redelegate
     */
    function verifier_redelegate(
        delegateData calldata delegate_data,
        bytes memory signature
    ) external onlyRole(FORWARDER_ROLE) {
        require(
            ICarvProtocolNFT(nft_address).ownerOf(delegate_data.tokenId) ==
                delegate_data.from,
            "CarvProtocolService: nft owner is invalid"
        );
        require(
            delegate_data.nonce > nonce,
            "CarvProtocolService: nonce is invalid"
        );
        // make sure signature is valid and get the address of the signer
        address _signer = _delegate_recover(delegate_data, signature);
        require(
            _signer == delegate_data.from,
            "CarvProtocolService: verify the signature failed"
        );

        // make sure run once a day
        // require(
        //     block.timestamp >= delegate_data.timestamp + DAY_IN_SECONDS,
        //     "CarvProtocolService: can only be sumbited once a day"
        // );

        address old_delegated_address = _verifier_delegate_addresss_map[
            delegate_data.from
        ][delegate_data.tokenId];

        _verifier_weight_changed(old_delegated_address, delegate_data.to);
        _verifier_delegate_addresss_map[delegate_data.from][
            delegate_data.tokenId
        ] = delegate_data.to;

        nonce++;
        emit VerifierWeightChanged(delegate_data.from, delegate_data.to);
    }

    /**
        @notice verifier_undelegate
     */
    function verifier_undelegate(
        delegateData calldata delegate_data,
        bytes memory signature
    ) external onlyRole(FORWARDER_ROLE) {
        require(
            ICarvProtocolNFT(nft_address).ownerOf(delegate_data.tokenId) ==
                delegate_data.from,
            "CarvProtocolService: nft owner is invalid"
        );
        require(
            delegate_data.nonce > nonce,
            "CarvProtocolService: nonce is invalid"
        );
        // make sure signature is valid and get the address of the signer
        address _signer = _delegate_recover(delegate_data, signature);
        require(_signer == delegate_data.from, "verify the signature failed");

        // make sure run once a day
        // require(
        //     block.timestamp >= delegate_data.timestamp + DAY_IN_SECONDS,
        //     "CarvProtocolService: can only be sumbited once a day"
        // );

        address old_delegated_address = _verifier_delegate_addresss_map[
            delegate_data.from
        ][delegate_data.tokenId];

        _verifier_weight_changed(old_delegated_address, delegate_data.from);
        _verifier_delegate_addresss_map[delegate_data.from][
            delegate_data.tokenId
        ] = address(0);

        emit VerifierWeightChanged(delegate_data.from, delegate_data.to);
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
    ) external onlyRole(TEE_ROLE) {
        bytes32 attestation_id = keccak256(bytes(attestation));
        attestation_id_list.push(attestation_id);
        attestation_id_map[attestation_id] = true;

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

        require(attestation_id_map[attestation_id], "attestation is not exist");
        require(
            !_is_verified_by_same_verifier(attestation_id),
            "attestation can not by verify again"
        );

        _attestation_id_verifiers_map[attestation_id].push(msg.sender);
        if (_is_verifer_sign_enough(attestation_id) && result) {
            pay_platform_profit(msg.sender);
            attestation_id_result_map[attestation_id] = result;
        }

        verifier_block[msg.sender] = block.number;

        emit VerifyAttestation(msg.sender, attestation_id, result);
    }

    function verify_attestation_batch(
        bytes32[] calldata attestation_ids,
        bool[] calldata results
    ) external {
        require(
            address_vote_weight[msg.sender] > 0,
            "CarvProtocolService: no vote weight"
        );

        uint256 nLen = attestation_ids.length;
        for (uint256 i = 0; i < nLen; i++) {
            require(
                attestation_id_map[attestation_ids[i]],
                "attestation is not exist"
            );
            _attestation_id_verifiers_map[attestation_ids[i]].push(msg.sender);
            if (_is_verifer_sign_enough(attestation_ids[i])) {
                pay_platform_profit(msg.sender);
                attestation_id_result_map[attestation_ids[i]] = results[i];
            }
        }

        verifier_block[msg.sender] = block.number;

        emit VerifyAttestationBatch(msg.sender, attestation_ids, results);
    }

    // ================== internal functions ==================

    function pay_platform_profit(address receiver) internal {
        uint256 profitAmount = ICarvVault(vault_address).getServiceProfit(
            address(this)
        );

        ICarvVault(vault_address).withdrawProfit(receiver);

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

    /**
     * @notice Verifies the signature for a given token_id, returning the address of the signer.
     * @param data token id of the given nft.
     */
    function _delegate_recover(
        delegateData calldata data,
        bytes memory signature
    ) internal returns (address) {
        // bytes32 hashStruct = keccak256(
        //     abi.encode(
        //         keccak256(
        //             "delegateData(address from,address to,uint256 tokenId,uint256 nonce,uint256 timestamp)"
        //         ),
        //         data.from,
        //         data.to,
        //         data.tokenId,
        //         data.timestamp
        //     )
        // );

        // return _get_recover_address(hashStruct, signature);
        return data.from;
    }

    /**
        @notice verifier_undelegate
     */
    function _verifier_weight_changed(address from, address to) internal {
        require(
            address_vote_weight[from] > 0,
            "CarvProtocolService: from vote weight is invalid"
        );
        address_vote_weight[from]--;

        address_vote_weight[to]++;
    }

    /**
     * @notice open_verifier_node
     */
    function open_verifier_node(
        openVerifierNodeData calldata verifier_data,
        bytes memory signature
    ) external {
        // make sure signature is valid and get the address of the signer
        address _signer = _open_verifier_node_recover(verifier_data, signature);
        address _nft_owner = ICarvProtocolNFT(nft_address).ownerOf(
            verifier_data.token_id
        );
        require(
            _signer == verifier_data.account,
            "verify the signature failed"
        );
        require(_signer == _nft_owner, "verify the nft owner failed");

        // make sure run once a day
        // require(
        //     block.timestamp >= verifier_data.timestamp + DAY_IN_SECONDS,
        //     "can only be sumbited once a day"
        // );

        // recode the verifier open status
        _verifier_node_is_open_map[verifier_data.token_id] = true;

        // emit the open verifier node event
        emit OpenVerifierNode(
            verifier_data.account,
            verifier_data.token_id,
            verifier_data.timestamp
        );
    }

    /**
     * @notice Verifies the signature for a given token_id, returning the address of the signer.
     * @param data token id of the given nft.
     */
    function _open_verifier_node_recover(
        openVerifierNodeData calldata data,
        bytes memory signature
    ) internal returns (address) {
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "openVerifierNodeData(address account,uint256 token_id,uint256 timestamp)"
                ),
                data.account,
                data.token_id,
                data.timestamp
            )
        );

        return _get_recover_address(hashStruct, signature);
    }

    /**
     * @notice Verifies the signature for a given token_id, returning the address of the signer.
     * @param hashStruct token id of the given nft.
     */
    function _get_recover_address(
        bytes32 hashStruct,
        bytes memory signature
    ) internal returns (address) {
        // 1. hashing the data (above is part of this) and generating the hashes
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", EIP712_DOMAIN_HASH, hashStruct)
        );
        emit RecoverParams(CHAIN_ID, EIP712_DOMAIN_HASH, hashStruct, digest);

        return ECDSAUpgradeable.recover(digest, signature);
    }

    /**
     * @notice close_verifier_node
     */
    function close_verifier_node(
        openVerifierNodeData calldata verifier_data
    ) external {}

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
