// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/security/Pausable.sol";

import "../ERC721.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is Pausable, ERC721 {
  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    if (paused()) revert InvalidCall();
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
