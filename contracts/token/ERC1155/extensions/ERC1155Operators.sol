// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev ERC721 token that allows operators to transfer and burn
 */
abstract contract ERC1155Operators is ERC1155 {
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
    address from, 
    uint256 tokenId, 
    uint256 amount
  ) public virtual onlyOperator {
    //now safely transfer
    _burn(from, tokenId, amount);
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can burn
   */
  function operatorBurnBatchFrom(
    address from, 
    uint256[] memory ids,
    uint256[] memory amounts
  ) public virtual onlyOperator {
    //now burn
    _burnBatch(from, ids, amounts);
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can transfer
   */
  function operatorTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) public virtual {
    operatorTransferFrom(from, to, tokenId, amount, "");
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can safely transfer
   */
  function operatorTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public virtual onlyOperator {
    //now safely transfer
    _safeTransferFrom(from, to, tokenId, amount, data);
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can transfer
   */
  function operatorTransferBatchFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public virtual {
    operatorTransferBatchFrom(from, to, ids, amounts, "");
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can safely transfer
   */
  function operatorTransferBatchFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual onlyOperator {
    //now safely transfer
    _safeBatchTransferFrom(from, to, ids, amounts, data);
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