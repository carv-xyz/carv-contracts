<h1 align="center">Tee Contract</h1>
<p align="center">Developed the function of Tee related Contract  </p>
<div align="center">

[![License: GPL v3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![type-badge](https://img.shields.io/badge/build-solidity-green)](https://img.shields.io/badge/build-solidity-green)
</div>

## Dependencies
Make sure you're running a version of node compliant with the `engines` requirement in `package.json`, or install Node Version Manager [`nvm`](https://github.com/creationix/nvm) and run `nvm use` to use the correct version of node.

Requires `nodejs` ,`yarn` and `npm`.

```shell
# node -v 
v16.0.0
# yarn version
yarn version v1.22.17 
# npm -v
8.5.3
```

## Quick Start
```shell
# Development library installation
yarn install

# yarn test from the hardhat 
yarn test

```

/////
1.发布到测试网络(sepolia)
https://sepolia.etherscan.io/

2.subgraph
https://thegraph.com/studio/subgraph/campaigns/playground/


graph init --product hosted-service xuxinlai2002/CarvProtocolService
cd CarvProtocolService
graph codegen && graph build

graph auth --product hosted-service 2fb42c7ab6944cf7aef59953a6c0db15
graph deploy --product hosted-service xuxinlai2002/CarvProtocolService

https://thegraph.com/hosted-service/subgraph/xuxinlai2002/CarvProtocolService


// address => has NFT 
// 