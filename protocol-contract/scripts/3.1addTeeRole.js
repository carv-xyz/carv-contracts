const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')

const main = async () => {

    let exAddress = "0x676A37eC9DC13f95133Fa86dBC053370a9417d8B";
    let { admin, tee2 } = await getInitAddress();

    let campaignsServiceAddress = await readConfig("1config", "CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CarvProtocalService", campaignsServiceAddress, admin);

    // await campaignsServiceContract.add_tee_role(admin.address)
    let isSucess = await isContractTransferSuccess(
        
        await campaignsServiceContract.add_tee_role(exAddress)
    )

    console.log("add tee role is ",isSucess);
   
    
}

main();

