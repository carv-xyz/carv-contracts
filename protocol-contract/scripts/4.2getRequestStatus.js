const {
    getInitAddress,
    readConfig,
    attachContract,
    isContractTransferSuccess
} = require('./utils/helper')

const gasPrice = "2100000000"
const gasLimit = "8000000"

const main = async () => {
 
    let requstId = "42587162534714066894977304865164634967471523788356526646745752615207944540824";
    let { admin } = await getInitAddress();
    let vrfServiceAddress = await readConfig("1config", "VRF_CONTRACT_ADDRESS");
    let vrfServiceContract = await attachContract("VrfService", vrfServiceAddress, admin);

    // await VrfService.requestRandomWords()
    let result = await vrfServiceContract.getRequestStatus(requstId)
    console.log("result is ",result);


}

main();

