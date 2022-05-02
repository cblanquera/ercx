// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
  /**
   * @dev The contract must not be paused.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    if(paused()) revert InvalidCall();
  }
}
