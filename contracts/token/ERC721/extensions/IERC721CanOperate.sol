// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev IERC721 interface that allows operators to transfer and burn
 */
interface IERC721CanOperate is IERC721 {
  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can burn
   */
  function operatorBurnFrom(uint256 tokenId) external;

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can transfer
   */
  function operatorTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * The operator can safely transfer
   */
  function operatorTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) external;
}