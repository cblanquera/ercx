// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
  uint256 private immutable _cap;

  /**
   * @dev Sets the value of the `cap`. This value is immutable, it can only be
   * set once during construction.
   */
  constructor(uint256 cap_) {
    if(cap_ == 0) revert InvalidCall();
    _cap = cap_;
  }

  /**
   * @dev Returns the cap on the token's total supply.
   */
  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  /** 
   * @dev Creates `amount` tokens and assigns them to `account`, 
   * increasing the total supply.
   */
  function _mint(address account, uint256 amount) internal virtual override {
    if((ERC20.totalSupply() + amount) > cap()) revert InvalidCall();
    super._mint(account, amount);
  }
}
