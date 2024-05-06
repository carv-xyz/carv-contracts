const {
    getInitAddress,
    readConfig,
    attachContract,
    isContractTransferSuccess
} = require('./utils/helper')

const gasPrice = "2100000000"
const gasLimit = "8000000"

const main = async () => {
 
    let { admin } = await getInitAddress();
    let vrfServiceAddress = await readConfig("1config", "VRF_CONTRACT_ADDRESS");
    let vrfServiceContract = await attachContract("VrfService", vrfServiceAddress, admin);

    // await VrfService.requestRandomWords()
    let isSucess = await isContractTransferSuccess(
        
        await vrfServiceContract.requestRandomWords(
            {
                gasPrice,
                gasLimit
            }
        )
    )

    console.log("add tee role is ",isSucess);


}

main();

