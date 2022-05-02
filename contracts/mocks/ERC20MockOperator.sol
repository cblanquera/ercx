// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20CanOperate.sol";

contract ERC20MockOperator {
  IERC20CanOperate private _token; 
  constructor(IERC20CanOperate token) {
    _token = token;
  }

  function transferFrom(address from, address to, uint256 amount) external {
    _token.operatorTransferFrom(from, to, amount);
  }

  function burnFrom(address from, uint256 amount) external {
    _token.operatorBurnFrom(from, amount);
  }
}