#! /usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

DEPLOY_ENV=testnet

HARDHAT_NETWORK=opbnb node "$SCRIPTPATH/multi-chain-deploy.js"
HARDHAT_NETWORK=arbitrumSepolia node "$SCRIPTPATH/multi-chain-deploy.js"
# HARDHAT_NETWORK=hardhat node "$SCRIPTPATH/multi-chain-deploy.js"
