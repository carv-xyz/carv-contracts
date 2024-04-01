require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-waffle')
require('hardhat-deploy')
require("@nomiclabs/hardhat-etherscan");

require('@openzeppelin/hardhat-upgrades');

const dotenv = require("dotenv");
dotenv.config({path: __dirname + '/.env'});
module.exports = {
  
  networks: {

    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/F1X0FmmZ95T61-D1LldN5QYam9D0amLn`,
      accounts: 
      [
        process.env.privateKey
      ]
    },
    
    opbnbMainnet: {
      url: "https://opbnb-mainnet-rpc.bnbchain.org/", 
      chainId: 204 , // Replace with the correct chainId for the "opbnb" network
      accounts: [process.env.privateKey], // Add private keys or mnemonics of accounts to use 
      gasPrice: 20000000,
      allowUnlimitedContractSize: true,

    },

    hardhat:{
      chainId:100,
      accounts:
      [
        process.env.privateKey
      ],
      blockGasLimit: 8000000
    },

    //base Testnet
    baseTest:
    {
      url: `https://goerli.base.org`,
      accounts: 
      [
        process.env.privateKey
      ]
    },

    //op Testnet
    opTest:
    {
      url: `https://goerli.optimism.io`,
      accounts: 
      [
        process.env.privateKey
      ]
    },

    //opbnb Testnet
    opbnbTest:
    {
      url: `https://opbnb-testnet-rpc.bnbchain.org`,
      chainId: 5611, // Replace with the correct chainId for the "opbnb" network
      accounts: 
      [
        process.env.privateKey
      ],
      gasPrice: 20000000000,
      allowUnlimitedContractSize: true,
    },

    arbitrumGoerli: {
      url: `https://goerli-rollup.arbitrum.io/rpc/`,
      accounts: 
      [
        process.env.privateKey
      ]
    },    

    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.apiKey}`,
      accounts: [
        process.env.privateKey
      ]
    },

  },


  // solidity: '0.8.17',
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: { 
          optimizer: {
            enabled: true,
            runs: 1
          }
        }
      },
  ]},
  
  settings: {
    optimizer: {
      enabled: false,
      runs: 1,
      details: {
        yul: true,
        yulDetails: {
          stackAllocation: true,
          optimizerSteps: "dhfoDgvulfnTUtnIf"
        }
      }
    }
  },

  etherscan: {
    apiKey: process.env.apiKey
  },
  
}
