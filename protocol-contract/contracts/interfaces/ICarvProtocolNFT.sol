// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

interface ICarvProtocolNFT {
    function address_vote_weight(address) external view returns (uint256);

    function mint(address _to, uint256 _tokenId) external;

    function batchMint(
        address[] calldata _receivers,
        uint256 _tokenIdStart
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);
}
