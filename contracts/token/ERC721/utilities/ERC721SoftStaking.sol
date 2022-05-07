// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// ============ Errors ============

error InvalidCall();

// ============ Interfaces ============

interface IERC20Mintable is IERC20 {
  function mint(address to, uint256 amount) external;
}

interface IERC721TotalSupply is IERC721 {
  function totalSupply() external view returns(uint256);
}

// ============ Contract ============

/**
 * @dev Soft stake NFTs, get tokens. Staking NFTs remains in your wallet
 */
contract ERC721SoftStaking is Context, ReentrancyGuard {
  //used in unstake()
  using Address for address;

  // ============ Constants ============

  //tokens earned per second
  uint256 public immutable TOKEN_RATE;
  //this is the contract address for the ERC20
  IERC721TotalSupply public immutable NFT_ADDRESS;
  //this is the contract address for the ERC721
  IERC20Mintable public immutable TOKEN_ADDRESS;

  // ============ Storage ============

  //start time of a token staked
  mapping(uint256 => uint256) public since;

  // ============ Deploy ============

  constructor(
    IERC721TotalSupply nftAddress, 
    IERC20Mintable tokenAddress, 
    uint256 tokenRate
  ) {
    NFT_ADDRESS = nftAddress;
    TOKEN_ADDRESS = tokenAddress;
    TOKEN_RATE = tokenRate;
  }

  // ============ Read Methods ============

  /**
   * @dev Calculate how many a tokens an NFT earned
   */
  function releaseable(
    uint256 tokenId
  ) public virtual view returns(uint256) {
    if (since[tokenId] == 0) {
      return 0;
    }
    return (block.timestamp - since[tokenId]) * TOKEN_RATE;
  }

  /**
   * @dev Calculate how many a tokens a staker earned
   */
  function totalReleaseable(
    uint256[] memory tokenIds
  ) public virtual view returns(uint256 total) {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      total += releaseable(tokenIds[i]);
    }
  }

  // ============ Write Methods ============

  /**
   * @dev Releases tokens without unstaking
   */
  function release(
    uint256[] memory tokenIds
  ) public virtual nonReentrant {
    //get the staker
    address staker = _msgSender();
    uint256 toRelease = 0;
    uint256 timestamp = block.timestamp;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      //if not owner
      if (NFT_ADDRESS.ownerOf(tokenIds[i]) != staker) 
        revert InvalidCall();
      //add releaseable
      toRelease += releaseable(tokenIds[i]);
      //reset when staking started
      since[tokenIds[i]] = timestamp;
    }
    //next mint tokens
    address(TOKEN_ADDRESS).functionCall(
      abi.encodeWithSelector(
        TOKEN_ADDRESS.mint.selector, 
        staker, 
        toRelease
      ), 
      "Low-level mint failed"
    );
  }

  /**
   * @dev Stakes NFTs
   */
  function stake(uint256[] memory tokenIds) public virtual {
    //get the staker
    address staker = _msgSender();
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      //if (for some reason) token is already staked
      if (since[tokenId] > 0
        //or if not owner
        || NFT_ADDRESS.ownerOf(tokenId) != staker
      ) revert InvalidCall();
      //remember when staking started
      since[tokenId] = block.timestamp;
    }
  }

  /**
   * @dev Unstakes NFTs and releases tokens
   */
  function unstake(
    uint256[] memory tokenIds
  ) public virtual nonReentrant {
    //get the staker
    address staker = _msgSender();
    uint256 toRelease = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      //if not owner
      if (NFT_ADDRESS.ownerOf(tokenIds[i]) != staker) 
        revert InvalidCall();
      //add releasable
      toRelease += releaseable(tokenIds[i]);
      //zero out the start date
      since[tokenIds[i]] = 0;
    }

    //next mint tokens
    address(TOKEN_ADDRESS).functionCall(
      abi.encodeWithSelector(TOKEN_ADDRESS.mint.selector, staker, toRelease), 
      "Low-level mint failed"
    );
  }
}