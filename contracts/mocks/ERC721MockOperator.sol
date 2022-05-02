// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721CanOperate.sol";

contract ERC721MockOperator {
  IERC721CanOperate private _token; 
  constructor(IERC721CanOperate token) {
    _token = token;
  }

  function transferFrom(address from, address to, uint256 tokenId) external {
    _token.operatorTransferFrom(from, to, tokenId);
  }

  function burnFrom(uint256 tokenId) external {
    _token.operatorBurnFrom(tokenId);
  }
}