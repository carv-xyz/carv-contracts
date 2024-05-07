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
} = require('./utils/helper')

const deployEnv = process.env.DEPLOY_ENV || "testnet";

const configFile = "multi-chain-config";
const chainId = hre.network.config.chainId;
// deploy erc20
const deployERC20 = async () => {
  let totalSupply = 100000000000000;

  const usdtFac = await hre.ethers.getContractFactory("TestERC20");
  const usdtIns = await usdtFac.deploy("USDT", "USDT", totalSupply);
  await usdtIns.deployed();
  await writeConfig(configFile, configFile, "USDT_CONTRACT_ADDRESS" + chainId, usdtIns.address);

  console.log("Mock USDT Contract :", usdtIns.address);
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
const deployProxy = async (logicContract, proxyAdmin) => {
  const proxy = await hre.ethers.deployContract("TransparentUpgradeableProxy", [logicContract, proxyAdmin, "0x"]);
  console.log("Proxy" + proxyIndex + " address is : ", proxy.address);
  await proxy.deployed();
  proxyIndex++;
  await writeConfig(configFile, configFile, "PROXY_CONTRACT_ADDRESS" + proxyIndex + chainId, proxy.address);
  return proxy;
}

const initNFTContract = async (contractIns, name, symbol) => {
  const initRes = await contractIns.initialize(name, symbol);
  await initRes.wait();
  console.log("CarvProtocol Contract initialized: ", initRes.hash);
  await writeConfig(configFile, configFile, "INIT_NFT_Contract" + chainId, initRes.hash);
}

const initCARVProtocolContract = async (contractIns, vaultAddress, nftAddress) => {
  const initRes = await contractIns.initialize(vaultAddress, nftAddress, hre.network.config.chainId);
  await initRes.wait();
  console.log("CarvProtocol Contract initialized: ", initRes.hash);
  await writeConfig(configFile, configFile, "INIT_CARV_PROTOCOL_Contract" + chainId, initRes.hash);
}

async function main () {
  console.log(
    "=== Deploying for chain:",
    hre.network.name,
    "env:",
    deployEnv,
    "==="
  );
  const usdt = await deployERC20();
  const nft = await deployCARVNFT();
  const proxyAdmin = await deployProxyAdmin();
  const proxy = await deployProxy(nft.address, proxyAdmin.address);
  await initNFTContract(nft, "CARVProtocolNft", "CNFT");

  const vault = await deployCARVault(usdt.address);
  const carvProtocolIns = await deployCarvProtocol();
  const proxy2 = await deployProxy(carvProtocolIns.address, proxyAdmin.address);
  await initCARVProtocolContract(carvProtocolIns, vault.address, nft.address);
  console.log(
    "=== Deployment complete, chain:",
    chalk.yellow.bgBlack.bold(hre.network.name),
    chalk.blue.bgBlack.bold(hre.network.config.chainId),
    "==="
  );
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
