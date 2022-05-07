// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
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
 * @dev Hard stake NFTs, get tokens. Staking transfers NFTs to this 
 * contract
 */
contract ERC721HardStaking is Context, ReentrancyGuard, IERC721Receiver {
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

  //mapping of owners to tokens
  mapping(address => uint256[]) public stakers;
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
  function releaseable(uint256 tokenId) public view returns(uint256) {
    if (since[tokenId] == 0) {
      return 0;
    }
    return (block.timestamp - since[tokenId]) * TOKEN_RATE;
  }

  /**
   * @dev Calculate how many a tokens a staker earned
   */
  function totalReleaseable(address staker) 
    public view returns(uint256 total) 
  {
    for (uint256 i = 0; i < stakers[staker].length; i++) {
      total += releaseable(stakers[staker][i]);
    }
  }

  // ============ Write Methods ============

  /**
   * @dev allows to receive tokens
   */
  function onERC721Received(
    address, 
    address, 
    uint256, 
    bytes calldata
  ) public virtual pure returns(bytes4) {
    return 0x150b7a02;
  }

  /**
   * @dev Releases tokens without unstaking
   */
  function release() public virtual nonReentrant {
    //get the staker
    address staker = _msgSender();
    if (stakers[staker].length == 0) revert InvalidCall();
    uint256 toRelease = 0;
    for (uint256 i = 0; i < stakers[staker].length; i++) {
      toRelease += releaseable(stakers[staker][i]);
      //reset when staking started
      since[stakers[staker][i]] = block.timestamp;
    }
    //next mint tokens
    address(TOKEN_ADDRESS).functionCall(
      abi.encodeWithSelector(TOKEN_ADDRESS.mint.selector, staker, toRelease), 
      "Low-level mint failed"
    );
  }

  /**
   * @dev Stakes NFTs, this contract needs to be approved to transfer
   * before calling this.
   */
  function stake(uint256[] memory tokenIds) public virtual {
    if (tokenIds.length == 0) revert InvalidCall();
    //get the staker
    address staker = _msgSender();
    //remember when started
    uint256 start = block.timestamp;
    //index is 0 anyways, we just need to declare it
    uint256 index;
    //now loop
    do {
      uint256 tokenId = tokenIds[index++];
      //if (for some reason) token is already staked
      if (since[tokenId] > 0) revert InvalidCall();
      //transfer token to here
      //if the staker is not the owner of the token, it should fail
      NFT_ADDRESS.safeTransferFrom(staker, address(this), tokenId);
      //add staker so we know who to return this to
      stakers[staker].push(tokenId);
      //remember when staking started
      since[tokenId] = start;
    } while (index < tokenIds.length);
  }

  /**
   * @dev Unstakes specific NFTs and releases tokens
   */
  function unstake(uint256[] memory tokenIds) public virtual nonReentrant {
    if (tokenIds.length == 0) revert InvalidCall();
    //get the staker
    address staker = _msgSender();
    //index is 0 anyways, we just need to declare it
    uint256 index;
    //calc releaseable
    uint256 toRelease;
    //now loop
    do {
      uint256 tokenId = tokenIds[index++];
      uint256 position = _indexOfTokenId(staker, tokenId);
      //calc and add to releaseable
      toRelease += releaseable(tokenId);
      //transfer token to staker
      NFT_ADDRESS.safeTransferFrom(
        address(this), 
        staker, 
        tokenId
      );
      //remove token id from staker list
      stakers[staker][position] = stakers[staker][stakers[staker].length - 1];
      stakers[staker].pop();
      //zero out the start date
      since[tokenId] = 0;
    } while (index < tokenIds.length);
  }

  /**
   * @dev Unstakes All NFTs and releases tokens
   */
  function unstakeAll() public virtual nonReentrant {
    //get the staker
    address staker = _msgSender();
    if (stakers[staker].length == 0) revert InvalidCall();
    uint256 toRelease = 0;
    for (uint256 i = 0; i < stakers[staker].length; i++) {
      toRelease += releaseable(stakers[staker][i]);
      //transfer token to staker
      NFT_ADDRESS.safeTransferFrom(
        address(this), 
        staker, 
        stakers[staker][i]
      );
      //zero out the start date
      since[stakers[staker][i]] = 0;
    }

    //remove the staker
    delete stakers[staker];

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
   * @dev Returns the index position of a `tokenId` from the `staker` list
   */
  function _indexOfTokenId(
    address staker, 
    uint256 tokenId
  ) private view returns(uint256) {
    for (uint256 i; i < stakers[staker].length; i++) {
      if (stakers[staker][i] == tokenId) {
        return i;
      }
    }
    revert InvalidCall();
  }
}