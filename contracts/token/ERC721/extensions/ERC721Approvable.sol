// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token where the admin can control what's approvable
 */
abstract contract ERC721Approvable is ERC721 {
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
    address to,
    uint256 tokenId,
    address owner
  ) internal virtual override {
    if (!_approved) revert InvalidCall();
    super._approve(to, tokenId, owner);
  }

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any 
   * token owned by the caller.
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
