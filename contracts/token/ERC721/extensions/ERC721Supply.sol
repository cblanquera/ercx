// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with token supply
 */
abstract contract ERC721Supply is ERC721 {
  //stores the total supply
  uint256 private _totalSupply;

  /**
   * @dev Returns the total supply
   */
  function totalSupply() public virtual view returns(uint256) {
    return _totalSupply;
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting and burning.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    //if minting
    if (from == address(0)) {
      _totalSupply++;
    //if burning
    } else if (to == address(0)) {
      _totalSupply--;
    }
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
