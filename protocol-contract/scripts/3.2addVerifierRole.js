const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')

const main = async () => {

    let exAddress = "0x0f12C9953765b4239e72B01E456948bC7103fDB6";

    let { admin } = await getInitAddress();

    let campaignsServiceAddress = await readConfig("1config", "CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CarvProtocalService", campaignsServiceAddress, admin);

    // await campaignsServiceContract.add_tee_role(admin.address)
    let isSucess = await isContractTransferSuccess(
        
        await campaignsServiceContract.add_verifier_role(exAddress)
    )

    console.log("add verifer role is ",isSucess);
   
    
}

main();

