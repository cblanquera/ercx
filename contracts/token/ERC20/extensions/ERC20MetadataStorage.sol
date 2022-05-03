// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
abstract contract ERC20MetadataStorage is ERC20 {
  string private _name;
  string private _symbol;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public virtual view returns(string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() public virtual view returns(string memory) {
    return _symbol;
  }
}
