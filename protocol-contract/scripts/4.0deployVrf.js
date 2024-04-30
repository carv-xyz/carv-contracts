const {
    getInitAddress,
    deployContract,
    writeConfig,
} = require('./utils/helper')

const main = async () => {
 
    let { partern } = await getInitAddress();
    // let symbol = 6;
    console.log("xxl partern : ",partern.address);

    vrfContract = await deployContract(partern,"VrfService",339);
    await writeConfig("1config","1config","VRF_CONTRACT_ADDRESS",vrfContract.address);

    console.log("Partern Address    :" ,partern.address);
    console.log("vrf Contract :" ,vrfContract.address);

}

main();

