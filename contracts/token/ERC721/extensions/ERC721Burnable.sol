// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "../ERC721.sol";

/**
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {

  // ============ Write Methods ============

  /**
   * @dev Allows owner to burn their token
   */
  function burn(uint256 tokenId) public virtual {
    address owner = ownerOf(tokenId);
    address spender = _msgSender();
    //not owner and not approved
    if (spender != owner 
      && getApproved(tokenId) != spender 
      && !isApprovedForAll(owner, spender)
    ) revert InvalidCall();
    //okay burn it
    _burn(tokenId);
  }
}
