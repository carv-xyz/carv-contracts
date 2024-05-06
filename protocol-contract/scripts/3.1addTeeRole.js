const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')

const main = async () => {

    // 0x4b079492Cd0713fEbE066E5fa6C1658c77Ec48F2
    // 0x4580C0DD2b7AD175198Ba15DA4c53Bf9034FED76
    let exAddress = "0x4b079492Cd0713fEbE066E5fa6C1658c77Ec48F2";
    let { admin, tee2 } = await getInitAddress();

    let campaignsServiceAddress = await readConfig("1config", "CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CarvProtocolService", campaignsServiceAddress, admin);

    // await campaignsServiceContract.add_tee_role(admin.address)
    let isSucess = await isContractTransferSuccess(
        
        await campaignsServiceContract.add_tee_role(exAddress)
    )

    console.log("add tee role is ",isSucess);
   
    
}

main();

