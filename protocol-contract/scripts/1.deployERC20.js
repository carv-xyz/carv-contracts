const {
    getInitAddress,
    deployContract,
    writeConfig,
} = require('./utils/helper')

const main = async () => {
 
    let { partern } = await getInitAddress();
    let totalSupply = 100000000000000;
    // let symbol = 6;
    console.log("xxl partern : ",partern.address);

    usdtContract = await deployContract(partern,"TestERC20","USDT","USDT",totalSupply);
    await writeConfig("1config","1config","USDT_CONTRACT_ADDRESS",usdtContract.address);

    console.log("Partern Address    :" ,partern.address);
    console.log("Mock USDT Contract :" ,usdtContract.address);

}

main();

