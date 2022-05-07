// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token where the admin can control what's approvable
 */
abstract contract ERC721Approvable is ERC721 {
  bool private _approvedAll = true;
  mapping(uint256 => bool) private _notApproved;

  /**
   * @dev Returns true if approvable
   */
  function isApprovable() public virtual view returns(bool) {
    return _approvedAll;
  }

  /**
   * @dev Returns true if approvable
   */
  function isApprovable(uint256 tokenId) public virtual view returns(bool) {
    return _approvedAll && !_notApproved[tokenId];
  }

  /**
   * @dev Checks to see if appprovable before approving
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) internal virtual override {
    if (!isApprovable(tokenId)) revert InvalidCall();
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
    if (!_approvedAll) revert InvalidCall();
    super._setApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Allows or denies tokens to be approvable
   */
  function _approvable(bool yes) internal virtual {
    _approvedAll = yes;
  }

  /**
   * @dev Allows or denies tokens to be approvable
   */
  function _approvable(uint256 tokenId, bool yes) internal virtual {
    _notApproved[tokenId] = !yes;
  }
}
