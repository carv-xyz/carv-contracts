#! /usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

DEPLOY_ENV=testnet

# HARDHAT_NETWORK=opbnbTest node "$SCRIPTPATH/deploy.js"
# HARDHAT_NETWORK=arbitrumSepolia node "$SCRIPTPATH/deploy.js"
HARDHAT_NETWORK=hardhat node "$SCRIPTPATH/multi-chain-deploy.js"
