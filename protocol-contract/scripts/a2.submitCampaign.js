const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
    getTestData
} = require('./utils/helper')


const main = async () => {
 
    const amount = 200
    const num_limited = 10
    let { admin,partern } = await getInitAddress();
    let {campaign_id} = await getTestData()

    // let rewardAddress = await readConfig("1config","CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");

    // let campaingsAddress = await readConfig("1config","CAMPAIGNS_CONTRACT_ADDRESS");
    // let campaignsContract = await attachContract("Campaigns",campaingsAddress,admin);

    let usdtAddress = await readConfig("1config","USDT_CONTRACT_ADDRESS");
    let usdtContract = await attachContract("TestERC20",usdtAddress,admin);

    // isSucess = await isContractTransferSuccess(
    //     await campaignsContract.connect(partern).submit_campaign(reward_info,compaign_info)
    // )
  
    // if(isSucess){

    //     let campaign_return = await campaignsContract.get_campaign_by_id(campaign_id);
    //     console.log("campain return ",campaign_return);

    //     let rewardBalance = await usdtContract.balanceOf(rewardAddress)
    //     console.log("reward Balance ",rewardBalance);
    // }


    let carvAddress = await readConfig("1config","CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CarvProtocolService",carvAddress,admin);
    let requirementsJson = 
    [
      { 
        "ID":[
          {          
            "Type": "Email",
            "ID":"*",
            "Verifier": "CliqueCarv",
            "Rule": "125",
          },{
            "Type": "Steam",
            "ID":"<RE>",
            "Verifier": "CliqueCarv",
            "Rule": "458",
          }
        ],
        "Data":[{
          "Type":"Achieve",
          "Data":{"game":"abe"}
          }
        ],
        "Actions":[
          "SendEMail","Callback Uri"
        ],
        "Rewards":[ 
          {"Soul":500}
        ],
        "Limits":{
          "Count":10,
          "StartTime":123456,
          "EndTime":123456
        }
      }
    ];
  
    let compaign_info = {
        campaign_id: campaign_id,
        url:"http://ipfs",
        creator: partern.address,
        campaign_type: 0,
        
        reward_contract: usdtContract.address,
        reward_total_amount: amount,
        reward_count: num_limited,
        status: 0,
        start_time: 1690874219888,
        end_time: 1690874219888,
        requirements: JSON.stringify(requirementsJson)
    }
  
    let reward_info = {
      campaign_id: campaign_id,
      user_address: admin.address,
      reward_amount: amount,
      total_num: num_limited,
      contract_address: usdtContract.address,
      contract_type: 1
    }
  
    let isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(partern).submit_campaign(
        reward_info,compaign_info
      )
    )
    
    console.log("xxl isSucess ",isSucess);

    
}

main();

