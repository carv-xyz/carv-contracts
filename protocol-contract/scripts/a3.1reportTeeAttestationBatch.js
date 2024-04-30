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

    const campaign_id = "campaign_id-batch"
    let attestation_base = "attestation-batchs-"
    

    let carvAddress = await readConfig("1config","CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CarvProtocolService",carvAddress,admin);

    for(var i = 0 ;i < 100 ;i ++ ){

      attestation = attestation_base + i;
      let isSucess = await isContractTransferSuccess(
        await campaignsServiceContract.connect(partern).report_tee_attestation(
          campaign_id,attestation
        )
      )

      if(isSucess){
        console.log(`campaign_id : ${campaign_id} - attestation : ${attestation}`);
      }
     
      await sleep(5000);


    }

    
    

    
}

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

main();

