// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev ERC1155 token where the admin can control what's approvable
 */
abstract contract ERC1155Approvable is ERC1155 {
  bool private _approved = true;

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual override {
    if (!_approved) revert InvalidCall();
    super._setApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Allows or denies tokens to be approvable
   */
  function _approvable(bool yes) internal virtual {
    _approved = yes;
  }
}
