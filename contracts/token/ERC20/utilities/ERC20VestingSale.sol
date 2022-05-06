// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ============ Errors ============

error InvalidCall();

// ============ Interfaces ============

interface IMintableToken is IERC20 {
  function mint(address to, uint256 amount) external;
}

interface IVesting is IERC20 {
  function vest(
    address beneficiary, 
    uint256 amount, 
    uint256 startDate, 
    uint256 endDate
  ) external;
}

// ============ Contract ============

contract ERC20VestingSale is AccessControl, ReentrancyGuard {
  // ============ Constants ============

  bytes32 public constant FUNDER_ROLE = keccak256("FUNDER_ROLE");
  bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

  //the token being vested
  IMintableToken public immutable TOKEN;
  //the vesting rules
  IVesting public immutable VESTING;

  // ============ Storage ============

  //the MATIC price per token
  uint256 public currentTokenPrice;
  //the token limit that can be sold
  uint256 public currentTokenLimit;
  //the total tokens that are currently allocated
  uint256 public currentTokenAllocated;
  //the end date of vesting for future purchases
  uint256 public currentVestedDate;

  // ============ Deploy ============

  /**
   * @dev Sets the `token`, `treasury` and `economy` addresses. Grants 
   * `DEFAULT_ADMIN_ROLE` to the account that deploys the contract.
   */
  constructor(IMintableToken token, IVesting vesting, address admin) {
    //set up roles for the admin
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  
    TOKEN = token;
    VESTING = vesting;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns true if can buy
   */
  function purchaseable(uint256 amount) public view returns(bool) {
    // if there's an amount
    return amount > 0 
      //if there's a price
      && currentTokenPrice > 0 
      //if there's a limit
      && currentTokenLimit > 0 
      //if the amount is below the token limit
      && (currentTokenAllocated + amount) <= currentTokenLimit;
  }

  // ============ Write Methods ============

  /**
   * @dev Allows anyone to invest during the current stage for an `amount`
   */
  function buy(address beneficiary, uint256 amount) 
    external payable nonReentrant 
  {
    if (!purchaseable(amount)
      //calculate eth amount = 1000 * 0.000005 ether
      || msg.value < ((amount * currentTokenPrice) / 1 ether)
    ) revert InvalidCall();

    //last start vesting
    VESTING.vest(beneficiary, amount, block.timestamp, currentVestedDate);
    //add to allocated
    currentTokenAllocated += amount;
  }

  // ============ Admin Methods ============

  /**
   * @dev Sets the sale stage
   */
  function setStage(
    uint256 price, 
    uint256 limit, 
    uint256 date
  ) external onlyRole(CURATOR_ROLE) {
    currentTokenPrice = price;
    currentTokenLimit = limit;
    currentVestedDate = date;
  }

  /**
   * @dev Sends the entire contract balance to a `recipient`. 
   */
  function withdraw(address recipient) 
    external nonReentrant onlyRole(FUNDER_ROLE)
  {
    Address.sendValue(payable(recipient), address(this).balance);
  }
}