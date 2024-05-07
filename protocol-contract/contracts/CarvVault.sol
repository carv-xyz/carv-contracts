// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "./interfaces/ICarvVault.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CarvVault is Ownable, ICarvVault {
    address public carvTokenAddress;

    mapping(address => Profit) public serviceProfit;

    modifier validAccount() {
        require(
            serviceProfit[msg.sender].valid,
            "CarvVault: caller is not in the whitelist"
        );
        _;
    }

    constructor(address _CarvTokenAddress) {
        carvTokenAddress = _CarvTokenAddress;
    }

    function setCarvAddress(address _carvTokenAddress) public onlyOwner {
        carvTokenAddress = _carvTokenAddress;
    }

    function setServiceProfit(
        address _addressArr,
        Profit calldata _profit
    ) public onlyOwner {
        require(
            _profit.start_time < _profit.end_time,
            "CarvVault: start time is greater than end time"
        );
        require(_profit.profitAmount > 0, "CarvVault: profit amount is 0");

        serviceProfit[_addressArr] = _profit;
    }

    function getServiceProfit(
        address _serviceAddress
    ) public view returns (uint256) {
        return serviceProfit[_serviceAddress].profitAmount;
    }

    function depositProfit(
        address _serviceAddress,
        uint256 _amount
    ) public onlyOwner {
        require(_amount > 0, "CarvVault: amount is 0");
        IERC20(carvTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        serviceProfit[_serviceAddress].totalProfitAmount += _amount;
    }

    function withdrawProfit(address _to) public validAccount {
        require(
            serviceProfit[msg.sender].end_time > block.timestamp,
            "CarvVault: profit time is over"
        );
        require(
            serviceProfit[msg.sender].totalProfitAmount >=
                serviceProfit[msg.sender].profitAmount,
            "CarvVault: not enough profit amount"
        );

        serviceProfit[msg.sender].totalProfitAmount -= serviceProfit[msg.sender]
            .profitAmount;

        IERC20(carvTokenAddress).transfer(
            _to,
            serviceProfit[msg.sender].profitAmount
        );
    }

    // admin operation
    function withdrawSuplusProfit(
        address _serviceAddress,
        uint256 _amount,
        address to
    ) public onlyOwner {
        require(
            serviceProfit[_serviceAddress].totalProfitAmount >= _amount,
            "CarvVault: not enough profit amount"
        );
        require(_amount > 0, "CarvVault: amount is 0");

        IERC20(carvTokenAddress).transfer(to, _amount);
    }

    fallback() external {
        revert("CarvVault: Cannot receive ETH");
    }

    receive() external payable {
        revert("CarvVault: Cannot receive ETH");
    }
}
