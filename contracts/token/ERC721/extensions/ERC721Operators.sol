// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token that allows operators to transfer and burn
 */
abstract contract ERC721Operators is ERC721 {
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
  function operatorBurnFrom(uint256 tokenId) public virtual onlyOperator {
    //now safely transfer
    _burn(tokenId);
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can transfer
   */
  function operatorTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    operatorTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can safely transfer
   */
  function operatorTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual onlyOperator {
    //now safely transfer
    _safeTransfer(from, to, tokenId, _data);
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