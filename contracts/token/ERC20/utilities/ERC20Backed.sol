// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// ============ Errors ============

error InvalidAmount();

// ============ Inferfaces ============

interface IERC20Capped is IERC20 {
  function cap() external returns(uint256);
}

// ============ Contract ============

contract ERC20Backed is 
  AccessControl, 
  ReentrancyGuard,
  Pausable 
{
  using Address for address;
  using SafeMath for uint256;

  // ============ Events ============

  event ERC20Received(address indexed sender, uint256 amount);
  event ERC20Sent(address indexed recipient, uint256 amount);
  event Capitalized(address from, uint256 amount);

  // ============ Constants ============

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

  //this is the contract address for the ERC20 token
  IERC20Capped public immutable TOKEN;
  //this is the token cap of the ERC20 token
  uint256 public immutable TOKEN_CAP;

  // ============ Store ============

  //the eth balance allocated for withdrawal
  uint256 private _interestAmount;
  //the buy amount percent to allocate for withdrawal
  //where 10000 = 100.00% 
  uint256 private _interestPercent;
  //the buy for amount percent
  //where 10000 = 100.00% 
  uint256 private _buyForPercent;
  //the sell for amount percent
  //where 10000 = 100.00% 
  uint256 private _sellForPercent;

  // ============ Deploy ============

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the 
   * contract.
   */
  constructor(
    IERC20Capped token, 
    uint256 interestPercent, 
    uint256 buyForPercent, 
    uint256 sellForPercent, 
    address admin
  ) payable {
    //set up roles for the admin
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(PAUSER_ROLE, admin);
    //set the ERC20 token addresses
    TOKEN = token;
    //set the token cap
    TOKEN_CAP = token.cap();
    //set the percents
    _interestPercent = interestPercent;
    _buyForPercent = buyForPercent;
    _sellForPercent = sellForPercent;
  }

  /**
   * @dev The Ether received will be logged with {PaymentReceived} 
   * events. Note that these events are not fully reliable: it's 
   * possible for a contract to receive Ether without triggering this 
   * function. This only affects the reliability of the events, and not 
   * the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable virtual {
    emit Capitalized(_msgSender(), msg.value);
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the ether balance
   */
  function balanceEther() public view returns(uint256) {
    return address(this).balance - _interestAmount;
  }

  /**
   * @dev Returns the ERC20 token balance
   */
  function balanceToken() public view returns(uint256) {
    return TOKEN.balanceOf(address(this));
  }

  /**
   * @dev Returns the ether amount we are willing to buy ERC20 token for
   */
  function buyingFor(uint256 amount) public view returns(uint256) {
    return _buyingFor(amount, balanceEther());
  }

  /**
   * @dev Returns the ether amount we are willing to sell ERC20 token for
   */
  function sellingFor(uint256 amount) public view returns(uint256) {
    return _sellingFor(amount, balanceEther());
  }

  // ============ Write Methods ============

  /**
   * @dev Buys `amount` of ERC20 token 
   */
  function buy(address recipient, uint256 amount) 
    public payable whenNotPaused nonReentrant
  {
    uint256 value = _sellingFor(amount, balanceEther() - msg.value);
    if (value == 0 
      || msg.value < value
      || balanceToken() < amount
    ) revert InvalidAmount();
    //we already received the ether
    //so just send the tokens
    SafeERC20.safeTransfer(TOKEN, recipient, amount);
    //add to the interest
    _interestAmount += msg.value.mul(_interestPercent).div(10000);
    //emit the sent event
    emit ERC20Sent(recipient, amount);
  }

  /**
   * @dev Sells `amount` of ERC20 token 
   */
  function sell(address recipient, uint256 amount) 
    public whenNotPaused nonReentrant 
  {
    //check allowance
    if(TOKEN.allowance(recipient, address(this)) < amount) 
      revert InvalidAmount();
    //send the ether
    Address.sendValue(payable(recipient), buyingFor(amount));
    //now accept the payment
    SafeERC20.safeTransferFrom(TOKEN, recipient, address(this), amount);
    emit ERC20Received(recipient, amount);
  }

  // ============ Admin Methods ============

  /**
   * @dev Sets the buy for percent
   */
  function buyFor(uint256 percent) 
    public virtual onlyRole(CURATOR_ROLE) 
  {
    _buyForPercent = percent;
  }

  /**
   * @dev Sets the interest
   */
  function interest(uint256 percent) 
    public virtual onlyRole(CURATOR_ROLE) 
  {
    _interestPercent = percent;
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Sets the sell for percent
   */
  function sellFor(uint256 percent) 
    public virtual onlyRole(CURATOR_ROLE) 
  {
    _sellForPercent = percent;
  }

  /**
   * @dev Withdraws interest.
   */
  function withdraw(address recipient) 
    public virtual nonReentrant onlyRole(WITHDRAWER_ROLE) 
  {
    //send the interest
    Address.sendValue(payable(recipient), _interestAmount);
    _interestAmount = 0;
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  // ============ Internal Methods ============
  /**
   * @dev Returns the ether amount we are willing to buy ERC20 token for
   */
  function _buyingFor(uint256 amount, uint256 balance) internal view returns(uint256) {
    // (eth / cap) * amount
    return balance.mul(amount).mul(_buyForPercent).div(TOKEN_CAP).div(1000);
  }

  /**
   * @dev Returns the ether amount we are willing to sell ERC20 token for
   */
  function _sellingFor(uint256 amount, uint256 balance) internal view returns(uint256) {
    // (eth / cap) * amount
    return balance.mul(amount).mul(_sellForPercent).div(TOKEN_CAP).div(1000);
  }
}