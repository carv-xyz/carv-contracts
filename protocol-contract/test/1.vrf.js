/* External Imports */
// const { ethers, network,} = require('hardhat')
const { ethers, getChainId, upgrades, network } = require('hardhat')
const { utils } = require('ethers')
const chai = require('chai')
const { solidity } = require('ethereum-waffle')

const bitcoin = require("bitcoinjs-lib");
const { ECPairFactory } = require("ecpair");
const ecc = require("tiny-secp256k1");

const { prove, proofToHash, verify } = require('@roamin/ecvrf');
const elliptic = require('elliptic');


const { expect, assert } = chai

const {
  deployContract,
  isContractTransferSuccess
} = require('../scripts/utils/helper')

chai.use(solidity)

function sleep(ms) {
  return new Promise(resolve => setTimeout(() => resolve(), ms));
};

describe(`vrf`, () => {

  let vrfContract;

  before(`deploy contact and setting `, async () => {

    [deployer,partner,user,tee,v1,v2,v3,v4,v5] =  await ethers.getSigners();
  
    vrfContract = await deployContract(partner, "VRFGasHelper");
    console.log("vrf contract address : ",vrfContract.address);
    
  })


  it('1.get randmon', async function () {

      // https://www.2coins.org/bitcoin-publickey-x-y-cords
      let result = await vrfContract.gammaToHash(
        "0xe74aa6a0b779ab1438a3eaa3b208fa021f5fa21e52172a9efc1da096c0e535bc",
        "0xfd9a6c4b11713bb5ac9241918a27457d4282ac62bb5253655ec2e40a703f23e9"
      );
      console.log("xxl 1",result);
  })


  it('2.verify the result', async function () {

    // 03e74aa6a0b779ab1438a3eaa3b208fa021f5fa21e52172a9efc1da096c0e535bc
    // e74aa6a0b779ab1438a3eaa3b208fa021f5fa21e52172a9efc1da096c0e535bc
    // fd9a6c4b11713bb5ac9241918a27457d4282ac62bb5253655ec2e40a703f23e9
    // 104616164728335370933859477070722334824770138285958063934288113787204859671996
    // 114707992551980611274235125809228999391892089258003442963796431440993908106217

    // https://datatracker.ietf.org/doc/pdf/draft-irtf-cfrg-vrf-04
    const EC = new elliptic.ec('secp256k1');
    const SECRET = EC.keyPair({ priv: 'f7df6062568b52eeac4e81f3333b6e8d91c6c78b081a5af9a53d1be6419d26cd', privEnc: 'hex' });
    const msg = Buffer.from('sample').toString('hex');

    // VRF proof and hash output
    const proof = prove(SECRET.getPrivate(), msg);
    console.log("xxl proof : ",proof);


    const decodeProof = await vrfContract.decodeProof( "0x" + proof);
    console.log("xxl decodeProof : ",decodeProof);

    const result = await vrfContract.verify( 
      [
       "0xe74aa6a0b779ab1438a3eaa3b208fa021f5fa21e52172a9efc1da096c0e535bc",
      "0xfd9a6c4b11713bb5ac9241918a27457d4282ac62bb5253655ec2e40a703f23e9"
      ],
      decodeProof,
      "0x" + Buffer.from('sample').toString('hex')
    );
    console.log("xxl result : ",result);

     

    })

})
