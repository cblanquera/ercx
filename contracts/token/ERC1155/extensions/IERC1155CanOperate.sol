// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev ERC721 token that allows operators to transfer and burn
 */
interface IERC1155CanOperate is IERC1155 {
  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can burn
   */
  function operatorBurnFrom(
    address from, 
    uint256 tokenId, 
    uint256 amount
  ) external;

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can burn
   */
  function operatorBurnBatchFrom(
    address from, 
    uint256[] memory ids,
    uint256[] memory amounts
  ) external;

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can transfer
   */
  function operatorTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

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
  ) external;

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can transfer
   */
  function operatorTransferBatchFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) external;

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
  ) external;
}