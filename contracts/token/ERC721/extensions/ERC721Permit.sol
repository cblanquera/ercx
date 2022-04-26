// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../ERC721.sol";

/**
 * @dev ERC721 token where transfers can be signed off instead of 
 * needing to be approved
 */
abstract contract ERC721Permit is ERC721 {
  //mapping of messages and whether if it was consumed
  mapping(bytes32 => bool) private _consumed;

  /**
   * @dev Returns true if transfer message was consumed
   */
  function isPermitConsumed(
    address from,
    address to,
    uint256 tokenId,
    uint256 nonce
  ) public virtual view returns(bool) {
    //make a message
    bytes32 message = keccak256(abi.encodePacked(
      "transfer", 
      from, 
      to, 
      tokenId, 
      nonce
    ));

    return _consumed[message];
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * they can sign a message authorizing the transfer
   */
  function permit(
    address from,
    address to,
    uint256 tokenId,
    uint256 nonce,
    bytes memory signed
  ) public virtual {
    permit(from, to, tokenId, nonce, signed, "");
  }

  /**
   * @dev Instead of the owner needing to approve (and pay gas)
   * they can sign a message authorizing the safe transfer
   */
  function permit(
    address from,
    address to,
    uint256 tokenId,
    uint256 nonce,
    bytes memory signed,
    bytes memory _data
  ) public virtual {
    //make a message
    bytes32 message = keccak256(abi.encodePacked(
      "transfer", 
      from, 
      to, 
      tokenId, 
      nonce
    ));
    //make sure the owner signed this off
    if (_consumed[message] || ECDSA.recover(
      ECDSA.toEthSignedMessageHash(message),
      signed
    ) != from) revert InvalidCall();
    //consume this
    _consumed[message] = true;
    //now safely transfer
    _safeTransfer(from, to, tokenId, _data);
  }
}
