/* External Imports */
// const { ethers, network,} = require('hardhat')
const { ethers, getChainId, upgrades, network } = require('hardhat')
const { utils } = require('ethers')
const chai = require('chai')
const { solidity } = require('ethereum-waffle')
const { expect, assert } = chai

const {
  deployContract,
  deployUpgradeContract,
  isContractTransferSuccess
} = require('../scripts/utils/helper')

chai.use(solidity)

describe(`main process`, () => {

  let usdtContract, soulContract, campaignsServiceContract, nftCarvProtocolContract, carvVaultContract;
  let deployer, partner, user, tee, v1, v2, v3, v4, v5;
  const campaign_id = "bd0078f7-4a48-5764-92bf-353ccbcea6e2"
  const amount = 200
  const num_limited = 10
  let totalSupply = 100000000000000

  before(`deploy contract and setting `, async () => {

    let chainID = await getChainId();
    [deployer, partner, user, tee, v1, v2, v3, v4, v5] = await ethers.getSigners();
    console.log("chainID is :" + chainID);
    console.log("deployer   :" + deployer.address);
    console.log("partner    :" + partner.address);
    console.log("user       :" + user.address);
    console.log("tee        :" + tee.address);
    console.log("v1         :" + v1.address);
    console.log("v2         :" + v2.address);
    console.log("v3         :" + v3.address);
    console.log("v4         :" + v4.address);
    console.log("v5         :" + v5.address);

    usdtContract = await deployContract(partner, "TestERC20", "USDT", "USDT", totalSupply);
    soulContract = await deployContract(deployer, "TestERC20", "SOUL", "SOUL", totalSupply);



    nftCarvProtocolContract = await deployUpgradeContract(
      deployer, "CarvProtocolNFT", "CarvProtocolNFT", "CNT"
    );

    campaignsServiceContract = await deployUpgradeContract(
      deployer, "CarvProtocolService", usdtContract.address,
      nftCarvProtocolContract.address
    );

    // deploy carv vault
    carvVaultContract = await deployContract(deployer, "CarvVault", deployer.address, usdtContract.address);

    let isSucess = await isContractTransferSuccess(
      await usdtContract.connect(partner).approve(campaignsServiceContract.address, amount)
    )
    console.log("approve is ", isSucess);

    isSucess = await isContractTransferSuccess(
      await soulContract.connect(deployer).approve(campaignsServiceContract.address, amount * 100)
    )
    console.log("transfer is ", isSucess);

    isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.set_nft_address(nftCarvProtocolContract.address)
    );
    console.log("set_nft_address is ", isSucess);

    isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.set_verifier_pass_threshold(2)
    );
    console.log("set_verifier_pass_threshold is ", isSucess);


    isSucess = await isContractTransferSuccess(
      await carvVaultContract.connect(deployer).setServiceProfit(
        campaignsServiceContract.address,
        {
          valid: true,
          serviceAddress: campaignsServiceContract.address,
          profitAmount: 200,
          totalProfitAmount: 1000,
          start_time: 1690874219888,
          end_time: 1690874219889
        }
      )
    )
    console.log("setServiceProfit is ", isSucess);

    isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(deployer).set_vault_address(carvVaultContract.address)
    )
    console.log("set_vault_address is ", isSucess);
  })

  async function submit_campaign () {


    let requirementsJson =
      [
        {
          "ID": [
            {
              "Type": "Email",
              "ID": "*",
              "Verifier": "CliqueCarv",
              "Rule": "Unique",
            }, {
              "Type": "Steam",
              "ID": "<RE>",
              "Verifier": "CliqueCarv",
              "Rule": "Unique",
            }
          ],
          "Data": [{
            "Type": "Achieve",
            "Data": { "game": "xxxx" }
          }
          ],
          "Actions": [
            "SendEMail", "Callback Uri"
          ],
          "Rewards": [
            { "Soul": 500 }
          ],
          "Limits": {
            "Count": 10,
            "StartTime": 123456,
            "EndTime": 123456
          }
        }
      ];

    let compaign_info = {
      campaign_id: campaign_id,
      url: "http://ipfs",
      creator: partner.address,
      campaign_type: 0,

      reward_contract: usdtContract.address,
      reward_total_amount: amount,
      reward_count: num_limited,
      status: 0,
      start_time: 1690874219888,
      end_time: 1690874219888,
      requirements: JSON.stringify(requirementsJson)
    }

    let reward_info = {
      campaign_id: campaign_id,
      user_address: deployer.address,
      reward_amount: amount,
      total_num: num_limited,
      contract_address: usdtContract.address,
      contract_type: 1
    }

    let isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(partner).submit_campaign(
        reward_info, compaign_info
      )
    )
    return isSucess;
  }

  it('1.Parnter provides Campaign data and pays reward USDT (ERC20)', async function () {

    let isSucess = await submit_campaign();
    assert.equal(true, isSucess);

    let rewardBalance = await usdtContract.balanceOf(deployer.address)
    assert.equal(rewardBalance.toString(), amount.toString())

  })

  const MultiUserIDs = [
    {
      "userID": "openID2:steam:a000000000000000000000000000000000000000000000000000000000000001",
      "verifierUri1": "https://carv.io/verify/steam/a000000000000000000000000000000000000000000000000000000000000001",
      "memo": "memo1"
    },
    {
      "userID": "did:polgyonId:b000000000000000000000000000000000000000000000000000000000000002",
      "verifierUri1": "https://carv.io/verify/steam/b000000000000000000000000000000000000000000000000000000000000002",
      "memo": "memo1"
    }
  ]

  it('2.tee set identities root case', async function () {

    let new_user_profile = "ipsf://abc02"
    let new_profile_verison = 1

    // 
    const dataHash = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes(JSON.stringify(MultiUserIDs))
    );
    const dataHashBin = ethers.utils.arrayify(dataHash);
    const ethHash = ethers.utils.hashMessage(dataHashBin);

    const signature = await tee.signMessage(dataHashBin);

    let userIDS = new Array();
    MultiUserIDs.forEach(
      (MultiUserIDObj) => {
        userIDS.push(MultiUserIDObj.userID)
      }
    )

    // console.log("------------ xxl set_identities_root");
    let isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(tee).set_identities_root(
        user.address, new_user_profile, new_profile_verison, ethHash, signature)
      // user.address, tee.address, new_user_profile, new_profile_verison, ethHash, userIDS, signature)
    )

    if (isSucess) {
      return_profile = await campaignsServiceContract.address_user_map(user.address)

      assert.equal(new_user_profile, return_profile[1])
      assert.equal(new_profile_verison, return_profile[2])

    } else {
      console.log("set_identities_root error ");
    }

  })


  it('3.user submit data for campaign', async function () {
    let requirementsJson = [
      {
        Owner: "xxxx",
        ID: [
          {
            ID: "xxxxxx",
            Type: "Web2Account",
            Provider: "Steam",
            Owner: "xxx",
            Verifier: "Carv",
            Signature: "xxxxxx"
          },
          {
            ID: "xxx@gmail.com",
            Type: "Email",
            Provider: "Gmail",
            Owner: "xxx",
            Verifier: "Clique",
            Signature: "xxxxx"
          }
        ],
        Data: [
          {
            ID: "xxxxxx",
            Type: "Web2Account",
            Provider: "Steam",
            DataType: "Achievement",
            Content: {
              game: "xxxxxx",
              title: "xxxxxx",
              timestamp: "xxxxxxxx"
            },
            Verifier: "Carv",
            Signature: "xxxxxxx"
          }
        ],
        RewardAddress: [
          "AddressA"
        ],
        OwnerSig: "xxxxxx"
      }
    ]
    let isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(user).join_campaign(
        0, campaign_id, JSON.stringify(requirementsJson)
      )
    )
    assert.equal(true, isSucess);
  })

  // function report_tee_attestation(string calldata campaign_id,string calldata attestation) external only_tees{ 
  it('4.TEE report tee attestation', async function () {

    let isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(deployer).add_tee_role(tee.address),
      await campaignsServiceContract.connect(tee).report_tee_attestation(
        campaign_id, "xyz 1234")
    )

    if (isSucess) {
      let proofs = await campaignsServiceContract.get_proof_list()
      // console.log(proofs);
      assert.equal(proofs[0], "0x04687ed6a16affd383bc95916f149ff3098584a0ab1f746f894a52d79c72262b")
    }

  })

  it('5-1.verifier verify attestation :can not verify no weight', async function () {
    await expect(campaignsServiceContract.connect(deployer).verify_attestation(
      "0x04687ed6a16affd383bc95916f149ff3098584a0ab1f746f894a52d79c72262b", true))
      .to.be.revertedWith("CarvProtocolService: no vote weight");
  })

  it('5-2.verifier verify attestation : can not transfer nft', async function () {
    await nftCarvProtocolContract.connect(deployer).add_minter_role(campaignsServiceContract.address);
    await campaignsServiceContract.connect(deployer).mint(deployer.address);

    await expect(nftCarvProtocolContract.connect(deployer).transferFrom(deployer.address, v1.address, 1))
      .to.be.revertedWith("can not support transfer");
  })

  it('5-3.verifier verify attestation : delegate nft', async function () {
    await campaignsServiceContract.connect(deployer).mint(deployer.address);
    const bal = await nftCarvProtocolContract.balanceOf(deployer.address);
    let weight = await campaignsServiceContract.address_vote_weight(deployer.address);
    assert.equal(bal.toNumber(), weight.toNumber());

    await campaignsServiceContract.connect(deployer).verifier_delegate([v1.address], [1]);
    const bal1 = await nftCarvProtocolContract.balanceOf(v1.address);
    const weight1 = await campaignsServiceContract.address_vote_weight(v1.address);

    weight = await campaignsServiceContract.address_vote_weight(deployer.address);
    assert.equal(weight.toNumber(), 1);
    assert.equal(bal.toNumber(), weight1.toNumber() + weight.toNumber());
  })
  it('5-4.verifier verify attestation : delegated can verify', async function () {
    weight = await campaignsServiceContract.address_vote_weight(deployer.address);
    assert.equal(weight.toNumber(), 1);
    let isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(deployer).verify_attestation(
        "0x04687ed6a16affd383bc95916f149ff3098584a0ab1f746f894a52d79c72262b", true),
    )
    assert.equal(isSucess, true);
  })
  it('5.5. verifier verify attestation : delegated can not by verify again', async function () {
    await expect(campaignsServiceContract.connect(deployer).verify_attestation(
      "0x04687ed6a16affd383bc95916f149ff3098584a0ab1f746f894a52d79c72262b", true)
    ).to.be.revertedWith("attestation can not by verify again");
  })

  it('6.verifier verify attestation : true', async function () {
    let isSucess = await isContractTransferSuccess(

      // await campaignsServiceContract.connect(deployer).add_verifier_role(deployer.address),
      // await campaignsServiceContract.connect(deployer).verify_attestation(
      //   "0x04687ed6a16affd383bc95916f149ff3098584a0ab1f746f894a52d79c72262b",true),
      // carvVault deposit asset
      await usdtContract.connect(partner).transfer(deployer.address, 1000),
      await usdtContract.connect(deployer).approve(carvVaultContract.address, 1000),
      await carvVaultContract.connect(deployer).depositProfit(campaignsServiceContract.address, 1000),
      await campaignsServiceContract.mint(v1.address),
      await campaignsServiceContract.connect(v1).verify_attestation(
        "0x04687ed6a16affd383bc95916f149ff3098584a0ab1f746f894a52d79c72262b", true),
    )

    if (isSucess) {
      let result = await campaignsServiceContract.attestation_id_result_map(
        "0x04687ed6a16affd383bc95916f149ff3098584a0ab1f746f894a52d79c72262b"
      )
      assert.equal(result, true);
    }

    const v1Bal = await usdtContract.connect(v1).balanceOf(v1.address);
    assert.equal(v1Bal.toString(), amount.toString());
  })

  it('7.verifier verify the same attestation ', async function () {

    await expect(campaignsServiceContract.connect(deployer).verify_attestation(
      "0x04687ed6a16affd383bc95916f149ff3098584a0ab1f746f894a52d79c72262b", true)).to.be.revertedWith("attestation can not by verify again");
  })

})
