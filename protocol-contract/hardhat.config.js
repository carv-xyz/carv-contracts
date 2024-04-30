require('@nomiclabs/hardhat-ethers')
// require('@nomiclabs/hardhat-waffle')
require('hardhat-deploy')
// require("@nomiclabs/hardhat-etherscan");
// require("@nomicfoundation/hardhat-verify");
require('@openzeppelin/hardhat-upgrades');
// require("@nomicfoundation/hardhat-toolbox")

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
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000001",balance:"10000000000000000000000" },
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000002",balance:"10000000000000000000000" },
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000003",balance:"10000000000000000000000" },
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000004",balance:"10000000000000000000000" },
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000005",balance:"10000000000000000000000" },
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000006",balance:"10000000000000000000000" },
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000007",balance:"10000000000000000000000" },
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000008",balance:"10000000000000000000000" },
        { privateKey:"0x0000000000000000000000000000000000000000000000000000000000000009",balance:"10000000000000000000000" },
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
    opbnb:
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
    // https://sepolia-rollup.arbitrum.io/rpc
    arbitrumSepolia: {
      url: `https://sepolia-rollup.arbitrum.io/rpc`,
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
      {
        version: "0.6.12",
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
    apiKey: {
      opbnb: "80d774115b27420e93a1e8fd90c86860"
    },

    customChains: [
      {
        network: "opbnb",
        chainId: 5611, // Replace with the correct chainId for the "opbnb" network
        urls: {
          apiURL:
            "https://open-platform.nodereal.io/80d774115b27420e93a1e8fd90c86860/op-bnb-testnet/contract/",
          browserURL: "https://testnet.opbnbscan.com/",
        },
      },
    ],
  }
  
}

// https://etherscan.io/myapikey
// https://opbnb.bscscan.com/myapikey
// A9TYNSB1RZC713ZWRW44R4WY1CRYD9BDJ4
// GBV72V9YQDNW5G8EFPBHIV86ICH35C2JYF

// https://open-platform.nodereal.io/GBV72V9YQDNW5G8EFPBHIV86ICH35C2JYF/op-bnb-testnet/contract/