// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/utils/Context.sol";

// ============ Errors ============

error InvalidCall();

// ============ Contract ============

abstract contract ERC721 is Context, ERC165, IERC721 {

  // ============ Storage ============

  // Mapping from token ID to owner address
  mapping(uint256 => address) internal _owners;
  // Mapping owner address to token count
  mapping(address => uint256) internal _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // ============ Modifiers ============

  modifier isOwner(uint256 tokenId, address owner) {
    if (_owners[tokenId] != owner) revert InvalidCall();
    _;
  }

  modifier isToken(uint256 tokenId) {
    if (_owners[tokenId] == address(0)) revert InvalidCall();
    _;
  }

  modifier isNotToken(uint256 tokenId) {
    if (_owners[tokenId] != address(0)) revert InvalidCall();
    _;
  }

  modifier notZeroAddress(address location) {
    if (location == address(0)) revert InvalidCall();
    _;
  }

  modifier isApproved(address from, uint256 tokenId) {
    address spender = _msgSender();
    if (spender != from 
      && getApproved(tokenId) != spender 
      && !isApprovedForAll(from, spender)
    ) revert InvalidCall();
    _;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the number of tokens in `owner`'s account.
   */
  function balanceOf(
    address owner
  ) public virtual view returns(uint256 balance) {
    return _balances[owner];
  }

  /**
   * @dev Returns the account approved for `tokenId` token.
   */
  function getApproved(
    uint256 tokenId
  ) public virtual view returns(address operator) {
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Returns if the `operator` is allowed to manage all of the 
   * assets of `owner`.
   */
  function isApprovedForAll(
    address owner, 
    address operator
  ) public virtual view returns(bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Returns the owner of the `tokenId` token.
   */
  function ownerOf(
    uint256 tokenId
  ) public virtual view returns(address owner) {
    return _owners[tokenId];
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public 
    virtual 
    view 
    override(ERC165, IERC165) 
    returns(bool) 
  {
    return
      interfaceId == type(IERC721).interfaceId 
      || super.supportsInterface(interfaceId);
  }

  // ============ Approve Methods ============

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to 
   * another account. The approval is cleared when the token is 
   * transferred.
   */
  function approve(address to, uint256 tokenId) public virtual {
    address owner = _owners[tokenId];
    if (to == owner) revert InvalidCall();

    address sender = _msgSender();
    if (sender != owner && !isApprovedForAll(owner, sender)) 
      revert InvalidCall();

    _approve(to, tokenId, owner);
  }

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any 
   * token owned by the caller.
   */
  function setApprovalForAll(
    address operator, 
    bool approved
  ) public virtual {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId, address owner) 
    internal virtual 
  {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any 
   * token owned by the caller.
   */
  function _setApprovalForAll(
    address owner,
    address operator, 
    bool approved
  ) internal virtual {
    if (owner == operator) revert InvalidCall();
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  // ============ Burn Methods ============

  /**
   * @dev Blindly burns `tokenId`.
   */
  function _burn(uint256 tokenId) internal virtual isToken(tokenId) {
    address from = _owners[tokenId];
    //allow other contracts to tap into this
    _beforeTokenTransfer(from, address(0), tokenId);
    // Clear approvals
    _approve(address(0), tokenId, from);

    unchecked {
      _balances[from] -= 1;
      delete _owners[tokenId];
    }

    emit Transfer(from, address(0), tokenId);
  }

  // ============ Mint Methods ============

  /**
   * @dev Blindly mints `tokenId` to `to`.
   */
  function _mint(
    address to, 
    uint256 tokenId
  ) internal virtual notZeroAddress(to) isNotToken(tokenId) {
    //allow other contracts to tap into this
    _beforeTokenTransfer(address(0), to, tokenId);

    unchecked {
      _balances[to] += 1;
      _owners[tokenId] = to;
    }

    emit Transfer(address(0), to, tokenId);
  }
  
  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], 
   * with an additional `data` parameter which is forwarded in 
   * {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    //if smart contract
    if (to.code.length > 0
      //and not received
      && !_checkOnERC721Received(address(0), to, tokenId, _data)
    ) revert InvalidCall();
  }

  // ============ Transfer Methods ============

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, 
   * checking first that contract recipients are aware of the ERC721 
   * protocol to prevent tokens from being forever locked.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override isApproved(from, tokenId) {
    _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override isApproved(from, tokenId) {
    //go ahead and transfer
    _transfer(from, to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} 
   * on a target address. The call is not executed if the target address 
   * is not a contract.
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721Receiver(to).onERC721Received(
      _msgSender(), from, tokenId, _data
    ) returns (bytes4 retval) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert InvalidCall();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking 
   * first that contract recipients are aware of the ERC721 protocol to 
   * prevent tokens from being forever locked.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);
    //see: @openzep/utils/Address.sol
    if (to.code.length > 0
      && !_checkOnERC721Received(from, to, tokenId, data)
    ) revert InvalidCall();
  }

  /**
   * @dev Blindly transfers `tokenId` token from `from` to `to`.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual isToken(tokenId) isOwner(tokenId, from) {
    //allow other contracts to tap into this
    _beforeTokenTransfer(from, to, tokenId);

    unchecked {
      _balances[from] -= 1;
      _balances[to] += 1;
      _owners[tokenId] = to;
    }

    emit Transfer(from, to, tokenId);
  }

  // ============ TODO Methods ============

  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * amount - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` 
   *   will be transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}