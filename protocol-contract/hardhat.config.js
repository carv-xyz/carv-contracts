require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-waffle')
require('hardhat-deploy')
require("@nomiclabs/hardhat-etherscan");

require('@openzeppelin/hardhat-upgrades');

const dotenv = require("dotenv");
dotenv.config({ path: __dirname + '/.env' });
module.exports = {

  networks: {

    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/F1X0FmmZ95T61-D1LldN5QYam9D0amLn`,
      accounts:
        [
          process.env.PRIVATE_KEY
        ]
    },

    opbnbMainnet: {
      url: "https://opbnb-mainnet-rpc.bnbchain.org/",
      chainId: 204, // Replace with the correct chainId for the "opbnb" network
      accounts: [process.env.PRIVATE_KEY], // Add private keys or mnemonics of accounts to use 
      gasPrice: 20000000,
      allowUnlimitedContractSize: true,

    },

    hardhat: {
      chainId: 100,
      // accounts:
      //   [
      //     { privateKey: "0xa6392433fe30f2bf8564228240eddd41c7ad12ab5332438254054896790ceebe", balance: "10000000000000000000000" },
      //     { privateKey: "0xf143b04240e065984bc0507eb1583234643d64c948e1e0ae2ed4abf7d7aed06a", balance: "10000000000000000000000" },
      //     { privateKey: "0x49b9dd4e00cb10e691abaa1de4047f9c9d98b72b9ce43e1e12959b22f56a0289", balance: "10000000000000000000000" },
      //     { privateKey: "0xada29a473e2b777403e7d2dc3876c5be03ca6b60d97e37e9bd335b1ce05a2680", balance: "10000000000000000000000" },
      //   ],
      blockGasLimit: 8000000
    },

    //base Testnet
    baseTest:
    {
      url: `https://goerli.base.org`,
      accounts:
        [
          process.env.PRIVATE_KEY
        ]
    },

    //op Testnet
    opTest:
    {
      url: `https://goerli.optimism.io`,
      accounts:
        [
          process.env.PRIVATE_KEY
        ]
    },

    //opbnb Testnet
    opbnbTest:
    {
      url: `https://opbnb-testnet-rpc.bnbchain.org`,
      chainId: 5611, // Replace with the correct chainId for the "opbnb" network
      accounts:
        [
          process.env.PRIVATE_KEY
        ],
      gasPrice: 20000000000,
      allowUnlimitedContractSize: true,
    },

    arbitrumSepolia: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${process.env.ARBITRUM_SEPOLIA_KEY}`,
      chainId: 421614,
      accounts:
        [
          process.env.PRIVATE_KEY
        ],
      allowUnlimitedContractSize: true,
    },

    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.apiKey}`,
      accounts: [
        process.env.PRIVATE_KEY
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
      }
    ]
  },
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
