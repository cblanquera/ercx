// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/ERC1155Burnable.sol";
import "../token/ERC1155/extensions/ERC1155MetadataURI.sol";
import "../token/ERC1155/extensions/ERC1155Operators.sol";
import "../token/ERC1155/extensions/ERC1155Pausable.sol";
import "../token/ERC1155/extensions/ERC1155Permit.sol";
import "../token/ERC1155/extensions/ERC1155Supply.sol";

contract ERC1155Mock is 
  ERC1155Burnable, 
  ERC1155MetadataURI, 
  ERC1155Operators,
  ERC1155Pausable,
  ERC1155Permit,
  ERC1155Supply 
{
  /**
   * @dev Creates `amount` new tokens for `to`.
   */
  function mint(address to, uint256 tokenId, uint256 amount) public virtual {
    _mint(to, tokenId, amount, "");
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
   * @dev The contract must not be paused.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}