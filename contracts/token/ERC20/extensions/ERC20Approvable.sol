// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev ERC20 token where the admin can control what's approvable
 */
abstract contract ERC20Approvable is ERC20 {
  bool private _approved = true;

  /**
   * @dev Returns true if approvable
   */
  function isApprovable() public virtual view returns(bool) {
    return _approved;
  }

  /**
   * @dev Checks to see if appprovable before approving
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual override {
    if (!_approved) revert InvalidCall();
    super._approve(owner, spender, amount);
  }

  /**
   * @dev Allows or denies tokens to be approvable
   */
  function _approvable(bool yes) internal virtual {
    _approved = yes;
  }
}
