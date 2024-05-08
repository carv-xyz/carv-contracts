require('@nomiclabs/hardhat-ethers')
require('hardhat-deploy')
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');
require("hardhat-abi-exporter");
require('hardhat-contract-sizer');

require("./tasks/flattener");
const dotenv = require("dotenv");
dotenv.config({ path: __dirname + '/.env' });

const OPBNB_VERIFY_KEY = process.env.OPBNB_VERIFY_KEY;
const ARBITRUM_SEPOLIA_KEY = process.env.ARBITRUM_SEPOLIA_KEY;
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
      accounts:
        [
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000001", balance: "10000000000000000000000" },
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000002", balance: "10000000000000000000000" },
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000003", balance: "10000000000000000000000" },
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000004", balance: "10000000000000000000000" },
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000005", balance: "10000000000000000000000" },
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000006", balance: "10000000000000000000000" },
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000007", balance: "10000000000000000000000" },
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000008", balance: "10000000000000000000000" },
          { privateKey: "0x0000000000000000000000000000000000000000000000000000000000000009", balance: "10000000000000000000000" },
        ],
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
    opbnb:
    {
      url: `https://opbnb-testnet.nodereal.io/v1/9e210feafbec4ed9bd48f855c2bd979a`,
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
  abiExporter: {
    runOnCompile: true,
    clear: true
  },

  etherscan: {
    apiKey: {
      opbnb: OPBNB_VERIFY_KEY,
      arbitrumSepolia: ARBITRUM_SEPOLIA_KEY,
    },

    customChains: [
      {
        network: "opbnb",
        chainId: 5611, // Replace with the correct chainId for the "opbnb" network
        urls: {
          apiURL:
            `https://open-platform.nodereal.io/${OPBNB_VERIFY_KEY}/op-bnb-testnet/contract/`,
          browserURL: "https://testnet.opbnbscan.com/",
        },
      },
      {
        network: "arbitrumSepolia",
        chainId: 421614,
        urls: {
          apiURL:
            "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia.arbiscan.io/",
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