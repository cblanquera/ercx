// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// ============ Errors ============

error InvalidCall();

// ============ Contract ============

abstract contract ERC20 is Context, IERC20Metadata {
  // ============ Storage ============

  //mapping of owners to balance
  mapping(address => uint256) private _balances;
  //mapping of owners to operators to amount
  mapping(address => mapping(address => uint256)) private _allowances;
  //the current supply
  uint256 private _totalSupply;

  // ============ Modifiers ============

  modifier notZeroAddress(address location) {
    if (location == address(0)) revert InvalidCall();
    _;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   */
  function decimals() public pure virtual returns(uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply(
  ) public view virtual returns(uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(
    address account
  ) public view virtual returns(uint256) {
    return _balances[account];
  }

  // ============ Approval Methods ============

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This
   * is zero by default.
   */
  function allowance(
    address owner, 
    address spender
  ) public view virtual returns(uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's 
   * tokens.
   */
  function approve(
    address spender, 
    uint256 amount
  ) public virtual returns(bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by 
   * the caller.
   */
  function decreaseAllowance(
    address spender, 
    uint256 subtractedValue
  ) public virtual returns(bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    if (currentAllowance < subtractedValue) revert InvalidCall();
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by 
   * the caller.
   */
  function increaseAllowance(
    address spender, 
    uint256 addedValue
  ) public virtual returns(bool) {
    _approve(
      _msgSender(),
      spender, 
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the 
   * `owner` s tokens.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual notZeroAddress(owner) notZeroAddress(spender) {
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  // ============ Transfer Methods ============

  /**
   * @dev See {IERC20-transfer}.
   */
  function transfer(
    address recipient, 
    uint256 amount
  ) public virtual returns(bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual returns(bool) {
    _transfer(sender, recipient, amount);
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    if (currentAllowance < amount) revert InvalidCall();
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   */
  function _burn(
    address account, 
    uint256 amount
  ) internal virtual notZeroAddress(account) {

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    if (accountBalance < amount) revert InvalidCall();
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /** 
   * @dev Creates `amount` tokens and assigns them to `account`, 
   * increasing the total supply.
   */
  function _mint(
    address account, 
    uint256 amount
  ) internal virtual notZeroAddress(account) {
    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual notZeroAddress(sender) notZeroAddress(recipient) {
    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    if (senderBalance < amount) revert InvalidCall();
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  // ============ TODO Methods ============

  /**
   * @dev Hook that is called before any transfer of tokens. This 
   * includes minting and burning.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This 
   * includes minting and burning.
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}
