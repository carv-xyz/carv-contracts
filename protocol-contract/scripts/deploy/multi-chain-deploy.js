// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const chalk = require("chalk");
const {
  writeConfig,
} = require('../utils/helper')

const deployEnv = process.env.DEPLOY_ENV || "testnet";

const configFile = "multi-chain-config";
const chainId = hre.network.config.chainId;
// deploy erc20
const deployERC20 = async (name, symbol, totalSupply) => {

  const usdtFac = await hre.ethers.getContractFactory("TestERC20");
  const usdtIns = await usdtFac.deploy("USDT", "USDT", totalSupply);
  await usdtIns.deployed();
  await writeConfig(configFile, configFile, "USDT_CONTRACT_ADDRESS" + chainId, usdtIns.address);

  console.log(symbol + " Contract :", usdtIns.address);
  return usdtIns;
}

const deployCARVNFT = async () => {
  const carvNFTFac = await hre.ethers.getContractFactory("CarvProtocolNFT");
  const carvNFTIns = await carvNFTFac.deploy();
  await carvNFTIns.deployed();
  console.log("CarvNFT Contract :", carvNFTIns.address);
  await writeConfig(configFile, configFile, "CARV_NFT_CONTRACT_ADDRESS" + chainId, carvNFTIns.address);
  return carvNFTIns;
}

const deployCARVault = async (tokenAddress) => {
  const carvVaultFac = await hre.ethers.getContractFactory("CarvVault");
  const carvVaultIns = await carvVaultFac.deploy(tokenAddress);
  await carvVaultIns.deployed();
  console.log("CarvVault Contract :", carvVaultIns.address);
  await writeConfig(configFile, configFile, "CARV_VAULT_CONTRACT_ADDRESS" + chainId, carvVaultIns.address);
  return carvVaultIns;
}

// deployUpgradeCarvProtocol
const deployCarvProtocol = async () => {
  const carvProtocolFac = await hre.ethers.getContractFactory("CarvProtocolService");
  const carvProtocolIns = await carvProtocolFac.deploy();
  await carvProtocolIns.deployed();
  console.log("CarvProtocol Contract :", carvProtocolIns.address);
  await writeConfig(configFile, configFile, "CARV_PROTOCOL_CONTRACT_ADDRESS" + chainId, carvProtocolIns.address);
  return carvProtocolIns;
}

const deployProxyAdmin = async () => {
  const proxyAdmin = await hre.ethers.deployContract("ProxyAdmin", []);
  console.log("ProxyAdmin address is : ", proxyAdmin.address);
  await proxyAdmin.deployed();
  await writeConfig(configFile, configFile, "PROXY_ADMIN_CONTRACT_ADDRESS" + chainId, proxyAdmin.address);
  return proxyAdmin;

}
let proxyIndex = 1
const deployProxy = async (logicContractAddress, proxyAdminAddress) => {
  const proxy = await hre.ethers.deployContract("TransparentUpgradeableProxy", [logicContractAddress, proxyAdminAddress, "0x"]);
  console.log("Proxy" + proxyIndex + " address is : ", proxy.address);
  await proxy.deployed();
  proxyIndex++;
  await writeConfig(configFile, configFile, "PROXY_CONTRACT_ADDRESS" + proxyIndex + chainId, proxy.address);
  return proxy;
}

const initNFTContract = async (contractIns, name, symbol) => {
  const nftProxyIns = await hre.ethers.getContractAt("CarvProtocolNFT", contractIns.address);
  const initRes = await nftProxyIns.initialize(name, symbol);
  await initRes.wait();
  console.log("CarvProtocol Contract initialized: ", initRes.hash);
  await writeConfig(configFile, configFile, "INIT_NFT_Contract" + chainId, initRes.hash);
}

const initCARVProtocolContract = async (CARVProtocolContractAddress, vaultAddress, nftAddress) => {
  const carvProtocolIns = await hre.ethers.getContractAt("CarvProtocolService", CARVProtocolContractAddress);
  const initRes = await carvProtocolIns.initialize(vaultAddress, nftAddress, hre.network.config.chainId);
  await initRes.wait();
  console.log("CarvProtocol Contract initialized: ", initRes.hash);
  await writeConfig(configFile, configFile, "INIT_CARV_PROTOCOL_Contract" + chainId, initRes.hash);
}

const nftOperation = async (nftProxyAddress, toAddress, role) => {
  // grandRole
  const nftProxyIns = await hre.ethers.getContractAt("CarvProtocolNFT", nftProxyAddress);
  const grandRoleRes = await nftProxyIns.grantRole(role, toAddress);
  console.log(`NFT Contract Grant MINTER_ROLE to ${toAddress} : `, grandRoleRes.hash);

}

const carvProtocolServerMint = async (carvProtocolProxyAddress, toAddress) => {
  const carvProtocolIns = await hre.ethers.getContractAt("CarvProtocolService", carvProtocolProxyAddress);
  const mintRes = await carvProtocolIns.mint(toAddress);
  console.log(`Mint NFT to ${toAddress} : `, mintRes.hash);
}

const carvProtocolServerGrantRole = async (carvProtocolProxyAddress, role, toAddress) => {
  // grandRole
  const carvProtocolIns = await hre.ethers.getContractAt("CarvProtocolService", carvProtocolProxyAddress);
  const grandRoleRes = await carvProtocolIns.grantRole(role, toAddress);
  console.log(`Grant MINTER_ROLE to ${toAddress} : `, grandRoleRes.hash);
}

const proxyAdminUpgrade = async (proxyAdminAddress, proxyAddress, logicContractAddress) => {
  const proxyAdminIns = await hre.ethers.getContractAt("ProxyAdmin", proxyAdminAddress);
  const upgradeRes = await proxyAdminIns.upgrade(proxyAddress, logicContractAddress);
  console.log(`Upgrade Proxy to ${logicContractAddress} : `, upgradeRes.hash);

}

const setNftAddress = async (carvProtocolProxyAddress, nftAddress) => {
  const carvProtocolIns = await hre.ethers.getContractAt("CarvProtocolService", carvProtocolProxyAddress);
  const setNftRes = await carvProtocolIns.set_nft_address(nftAddress);
  console.log(`Set NFT address to ${nftAddress} : `, setNftRes.hash);

}

const vaultOperation = async (vaultAddress, tokenAddress, serviceAddress) => {
  const vaultIns = await hre.ethers.getContractAt("CarvVault", vaultAddress);
  const tokenIns = await hre.ethers.getContractAt("TestERC20", tokenAddress);

  // const approveRes = await tokenIns.approve(vaultAddress, hre.ethers.utils.parseEther("10"));
  // console.log(`Approve USDT to ${vaultAddress} : `, approveRes.hash);

  // const depositRes = await vaultIns.depositProfit(serviceAddress, "100000000000000");
  // console.log(`Deposit USDT to ${vaultAddress} : `, depositRes.hash);

  const setting = await vaultIns.setServiceProfit(
    serviceAddress,
    {
      valid: true,
      serviceAddress: serviceAddress,
      profitAmount: 1,
      totalProfitAmount: 100000000000,
      start_time: Math.floor(Date.now() / 1000),
      end_time: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30

    }
  );
  console.log(`Set Service Profit : `, setting.hash);

}

const addressWeight = async (carvProtocolProxyAddress, userAddress, idBytes) => {
  const carvProtocolIns = await hre.ethers.getContractAt("CarvProtocolService", carvProtocolProxyAddress);

  const weight = await carvProtocolIns.address_vote_weight(userAddress);
  console.log(`Address vote weight : `, weight);

  const idExist = await carvProtocolIns.attestation_id_map(idBytes)
  console.log(`ID exist : `, idExist);

  const vaultAddress = await carvProtocolIns.vault_address()
  console.log(`Vault address : `, vaultAddress);
  const pushRes = await carvProtocolIns.verify_attestation_batch([idBytes], [true])

  console.log(`Push attestation : `, pushRes.hash);
}

async function main () {
  //==========  contract deploy and init start ==========
  // console.log(
  //   "=== Deploying for chain:",
  //   hre.network.name,
  //   "env:",
  //   deployEnv,
  //   "==="
  // );
  // const usdt = await deployERC20();
  // const nft = await deployCARVNFT();
  // const proxyAdmin = await deployProxyAdmin();
  // const proxy = await deployProxy(nft.address, proxyAdmin.address);
  // await initNFTContract(proxy, "CARVProtocolNft", "CNFT");

  // const vault = await deployCARVault(usdt.address);

  // const carvProtocolIns = await deployCarvProtocol();
  // const proxy2 = await deployProxy(carvProtocolIns.address, proxyAdmin.address);

  // await initCARVProtocolContract(proxy2, vault.address, proxy.address);
  // await nftOperation(proxy.address, proxy2.address, "0x894106d7f75745d0351b88f31e48b7fdae7db2b459162bf05a6d9ecf3a8063d5");

  // const rayAddress = "0xb1878c4d1baabbb6abba3d77836cc85a80d5753b"
  // const teeRole = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TEE_ROLE"))
  // const forwartRole = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("FORWARDER_ROLE"))
  // await carvProtocolOperation(proxy2.address, forwartRole, rayAddress);
  // await carvProtocolOperation(proxy2.address, teeRole, rayAddress);

  // console.log(
  //   "=== Deployment complete, chain:",
  //   chalk.yellow.bgBlack.bold(hre.network.name),
  //   chalk.blue.bgBlack.bold(hre.network.config.chainId),
  //   "==="
  // );
  // ========== contract deploy and init end ==========

  // ========== contract operation start ==========
  // proxy2
  const proxy2Address = "0xbd9A9AC0172F9eddeBEa4172Fb7D9A3CA95ceE52"
  // // const toAddress = "0x7f57004E08ef1702b2b88b87ae01a561ae10F10e";
  // const rayAddress = "0xb1878c4d1baabbb6abba3d77836cc85a80d5753b"
  const xuanyuanAddress = "0x689d0b32Da0480095b7AE7b604f1b1997736B3F9"
  // const teeRole = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("TEE_ROLE"))
  const forwartRole = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("FORWARDER_ROLE"))
  // await carvProtocolOperation(proxy2Address, forwartRole, xuanyuanAddress);


  // ========== contract operation end ==========

  // ========== contract upgrade start ==========
  const proxyAdmin = "0xB51F25a002750fe07c32161cba6745744486d870"
  // const carvProtocolIns = await deployCarvProtocol();
  const proxy2 = "0xbd9A9AC0172F9eddeBEa4172Fb7D9A3CA95ceE52"
  // await proxyAdminUpgrade(proxyAdmin, proxy2, carvProtocolIns.address);
  // await initCARVProtocolContract(proxy2, vault, nft);
  // ========== contract upgrade end ==========

  // ========== nft deploy again start ==========
  // const nft = await deployCARVNFT();
  // const proxyAdmin = await deployProxyAdmin();
  // const proxy = await deployProxy(nft.address, proxyAdmin.address);
  // const proxy2 = "0xbd9A9AC0172F9eddeBEa4172Fb7D9A3CA95ceE52"
  // await initNFTContract(proxy, "CARVProtocolNft", "CNFT");
  // await setNftAddress(proxy2, proxy.address)

  // await nftOperation(proxy.address, proxy2, "0x894106d7f75745d0351b88f31e48b7fdae7db2b459162bf05a6d9ecf3a8063d5");

  // ========== nft deploy again end ==========

  // ========== vault operation start ==========
  // await vaultOperation("0x9AFEf3CE0d4b88127401b77e6eEd69e450Bd2400", "0x9f479E10762bDAB03E47f4C4229654dFE16fE8Fc", "0xbd9A9AC0172F9eddeBEa4172Fb7D9A3CA95ceE52");
  // ========== vault operation end ==========

  // ========== address weight start ==========
  await addressWeight(proxy2, "0x689d0b32Da0480095b7AE7b604f1b1997736B3F9", [140, 167, 237, 128, 48, 28, 124, 189, 9, 205, 149, 24, 184, 31, 220, 26, 52, 252, 86, 45, 220, 46, 158, 29, 48, 123, 20, 141, 5, 26, 40, 76]);
  // ========== address weight end ==========
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });
module.exports = {
  deployERC20,
  deployCARVNFT,
  deployCARVault,
  deployCarvProtocol,
  deployProxyAdmin,
  deployProxy,
  initNFTContract,
  initCARVProtocolContract,
  nftOperation,
  carvProtocolServerMint,
  carvProtocolServerGrantRole,
  proxyAdminUpgrade,
  setNftAddress,
  vaultOperation,
  addressWeight,
  initCARVProtocolContract
}