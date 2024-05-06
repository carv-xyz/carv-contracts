const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
    getTestData
} = require('./utils/helper')


const main = async () => {
 

    let { admin,partern } = await getInitAddress();
    // let {campaign_id} = await getTestData()

    const campaign_id = "campaign_id-0004"
    const attestation = "attestation-0004"
    

    let carvAddress = await readConfig("1config","CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CarvProtocolService",carvAddress,admin);

    let isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(partern).report_tee_attestation(
        campaign_id,attestation
      )
    )
    
    console.log("xxl isSucess ",isSucess);

    
}

main();

