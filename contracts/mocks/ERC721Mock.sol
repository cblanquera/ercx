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
   * @dev Creates `amount` new tokens for `to`.
   */
  function mint(address to, uint256 tokenId) public virtual {
    _mint(to, tokenId);
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual {
    _pause();
  }

  /**
   * @dev Adds or revokes an operator
   */
  function setOperator(address operator, bool add) public {
    _setOperator(operator, add);
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual {
    _unpause();
  }

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