const hre = require("hardhat");
const chalk = require("chalk");

const {
  deployERC20,
  deployCARVNFT,
  deployCarvProtocol,
  deployProxyAdmin,
  deployProxy,
  initNFTContract,
  deployCARVault,
  initCARVProtocolContract,
  nftOperation,
  carvProtocolServerGrantRole,
  vaultOperation
} = require("./multi-chain-deploy");
const deployEnv = process.env.DEPLOY_ENV || "testnet";

const FORWARDER_ADDRESS = process.env.FORWARDER_ADDRESS;
const TEE_ADDRESS = process.env.TEE_ADDRESS;
const TeeRole = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TEE_ROLE"))
const ForwardRole = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("FORWARDER_ROLE"))
const main = async () => {
  //==========  contract deploy and init start ==========
  console.log(
    "=== Deploying for chain:",
    hre.network.name,
    "env:",
    deployEnv,
    "==="
  );
  const usdt = await deployERC20("Ve-CARV", "VeCARV", hre.ethers.utils.parseEther("100000000"));
  const nft = await deployCARVNFT();
  const proxyAdmin = await deployProxyAdmin();
  const proxy = await deployProxy(nft.address, proxyAdmin.address);
  await initNFTContract(proxy, "CARVProtocolNft", "CNFT");

  const vault = await deployCARVault(usdt.address);

  const carvProtocolIns = await deployCarvProtocol();
  const proxy2 = await deployProxy(carvProtocolIns.address, proxyAdmin.address);

  await initCARVProtocolContract(proxy2.address, vault.address, proxy.address);
  await nftOperation(proxy.address, proxy2.address, "0x894106d7f75745d0351b88f31e48b7fdae7db2b459162bf05a6d9ecf3a8063d5");

  await carvProtocolServerGrantRole(proxy2.address, ForwardRole, FORWARDER_ADDRESS);
  await carvProtocolServerGrantRole(proxy2.address, TeeRole, TEE_ADDRESS);

  await vaultOperation(vault.address, proxy2.address, proxy.address);

  console.log(
    "=== Deployment complete, chain:",
    chalk.yellow.bgBlack.bold(hre.network.name),
    chalk.blue.bgBlack.bold(hre.network.config.chainId),
    "==="
  );

  // ========== contract deploy and init end ==========

};

main().catch(err => {
  console.error(err);
  process.exit(1);
});