// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract CarvProtocolNFT is ERC721Upgradeable {

    /**
        @notice Initializes CompaignsService, creates and grants {msg.sender} the admin role,
     */
    function __CarvProtocolNFT_init(string memory _name,string memory _symbol) public initializer  {
        __ERC721_init(_name,_symbol);
    }


    function mint(address _to,uint256 _tokenId) external{

        super._mint(_to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {        
        revert("do not support");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        revert("do not support");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("do not support");
    }


}
