// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/ERC20Burnable.sol";
import "../token/ERC20/extensions/ERC20Capped.sol";
import "../token/ERC20/extensions/ERC20MetadataStorage.sol";
import "../token/ERC20/extensions/ERC20Operators.sol";
import "../token/ERC20/extensions/ERC20Pausable.sol";
import "../token/ERC20/extensions/ERC20Permit.sol";

contract ERC20Mock is 
  ERC20Burnable, 
  ERC20Capped,
  ERC20MetadataStorage,
  ERC20Operators,
  ERC20Pausable,
  ERC20Permit
{
  /**
   * @dev Sets the name, symbol
   */
  constructor(
    string memory name_, 
    string memory symbol_, 
    uint256 cap_
  ) ERC20MetadataStorage(name_, symbol_) ERC20Capped(cap_) {}

  /**
   * @dev Hook that is called before any transfer of tokens. This 
   * includes minting and burning.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  /** 
   * @dev Creates `amount` tokens and assigns them to `account`, 
   * increasing the total supply.
   */
  function _mint(
    address account, 
    uint256 amount
  ) internal virtual override(ERC20, ERC20Capped) {
    super._mint(account, amount);
  }
}