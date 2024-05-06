// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

interface IVRF {
    
    function gammaToHash(uint256 gammaX, uint256 gammaY) external pure returns (bytes32);

}