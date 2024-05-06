const {
    getInitAddress,
    deployUpgradeContract,
    readConfig,
    writeConfig,
} = require('./utils/helper')

const main = async () => {
 

    let { admin } = await getInitAddress();

    let usdtAddress = await readConfig("1config", "CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let CarvProtocolServiceContract = await deployUpgradeContract(admin,"CarvProtocolService",usdtAddress);


    // await writeConfig("1config","1config","CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS",CarvProtocolServiceContract.address);

    console.log("Deployer Address :" ,admin.address);
    console.log("CarvProtocolService  Address :" ,CarvProtocolServiceContract.address);
    
}

main();

