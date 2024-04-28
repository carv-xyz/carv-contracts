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

// deploy erc20
const deployERC20 = async () => {
  let totalSupply = 100000000000000;

  const usdtFac = await hre.ethers.getContractFactory("TestERC20");
  const usdtIns = await usdtFac.deploy("USDT", "USDT", totalSupply);

  await writeConfig("1config", "1config", "USDT_CONTRACT_ADDRESS", usdtIns.address);

  console.log("Mock USDT Contract :", usdtIns.address);
  return usdtIns;
}


// deployUpgradeCarvProtocol
const deployUpgradeCarvProtocol = async (usdtAddress) => {
  const carvProtocolFac = await hre.ethers.getContractFactory("CarvProtocolService");
  const initContractName = "__CarvProtocolService_init"
  const carvProtocolIns = await hre.upgrades.deployProxy(carvProtocolFac, [usdtAddress],
    { initializer: initContractName }
  );
  console.log("CarvProtocal address is : ", carvProtocolIns.address);
  return carvProtocolIns;
}
async function main () {
  console.log(
    "=== Deploying for chain:",
    hre.network.name,
    "env:",
    deployEnv,
    "==="
  );

  const usdtContract = await deployERC20();

  await deployUpgradeCarvProtocol(usdtContract.address);

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
