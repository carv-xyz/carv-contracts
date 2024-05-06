// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

interface ICarvVault {
    struct Profit {
        bool valid;
        address serviceAddress;
        uint256 profitAmount;
        uint256 totalProfitAmount;
        uint256 start_time;
        uint256 end_time;
    }

    function getServiceProfit(
        address _serviceAddress
    ) external returns (uint256 profitAmount);

    function withdrawProfit(address _to) external;
}
