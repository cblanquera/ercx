// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Operators is ERC20 {
  //mapping of operator to exists
  mapping(address => bool) private _operators;

  modifier onlyOperator {
    if (!isOperator(_msgSender())) revert InvalidCall();
    _;
  }

  /**
   * @dev Returns true if `operator` is an operator
   */
  function isOperator(address operator) public virtual view returns(bool) {
    return _operators[operator];
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can burn
   */
  function operatorBurnFrom(
    address account, 
    uint256 amount
  ) public virtual onlyOperator {
    //now safely transfer
    _burn(account, amount);
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can safely transfer
   */
  function operatorTransferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual onlyOperator {
    //now safely transfer
    _transfer(from, to, amount);
  }

  /**
   * @dev Adds or revokes an operator
   */
  function _setOperator(address operator, bool add) internal {
    //an operator should be a contract
    if (operator.code.length == 0) revert InvalidCall();
    _operators[operator] = add;
  }
}