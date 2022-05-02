// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155CanOperate.sol";

contract ERC1155MockOperator {
  IERC1155CanOperate private _token; 
  constructor(IERC1155CanOperate token) {
    _token = token;
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can burn
   */
  function burnFrom(
    address from, 
    uint256 tokenId, 
    uint256 amount
  ) external {
    _token.operatorBurnFrom(from, tokenId, amount);
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can burn
   */
  function burnBatchFrom(
    address from, 
    uint256[] memory ids,
    uint256[] memory amounts
  ) external {
    _token.operatorBurnBatchFrom(from, ids, amounts);
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can transfer
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) external {
    _token.operatorTransferFrom(from, to, tokenId, amount);
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can transfer
   */
  function transferBatchFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) external {
    _token.operatorTransferBatchFrom(from, to, ids, amounts);
  }
}