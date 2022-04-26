// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/ERC721BaseTokenURI.sol";
import "../token/ERC721/extensions/ERC721Burnable.sol";
import "../token/ERC721/extensions/ERC721ContractURIStorage.sol";
import "../token/ERC721/extensions/ERC721MetadataStorage.sol";
import "../token/ERC721/extensions/ERC721Operators.sol";
import "../token/ERC721/extensions/ERC721Pausable.sol";
import "../token/ERC721/extensions/ERC721Permit.sol";
import "../token/ERC721/extensions/ERC721Supply.sol";

contract ERC721Mock is 
  ERC721BaseTokenURI,
  ERC721Burnable,
  ERC721ContractURIStorage,
  ERC721MetadataStorage,
  ERC721Operators,
  ERC721Pausable,
  ERC721Permit,
  ERC721Supply
{
  constructor(
    string memory name_, 
    string memory symbol_
  ) ERC721MetadataStorage(name_, symbol_) {}

  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Pausable, ERC721Supply) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}