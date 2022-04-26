// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// ============ Errors ============

error InvalidCall();

// ============ Contract ============

contract ERC1155 is Context, ERC165, IERC1155 {
  
  // ============ Storage ============

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) internal _balances;
  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  
  // ============ Modifiers ============

  modifier nonZeroAddress(address location) {
    //make sure address is not the zero address
    if (location == address(0)) revert InvalidCall();
    _;
  }

  modifier isOwnerOrApproved(address from) {
    if (from != _msgSender() && !isApprovedForAll(from, _msgSender()))
      revert InvalidCall();
    _;
  }

  modifier lengthMatches(uint256[] memory a, uint256[] memory b) {
    if (a.length != b.length) revert InvalidCall();
    _;
  }

  // ============ Read Methods ============

  /**
   * @dev See {IERC1155-balanceOf}.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id) 
    public view virtual override nonZeroAddress(account) returns(uint256) 
  {
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(
    address[] memory accounts, 
    uint256[] memory ids
  ) public view virtual override returns(uint256[] memory) {
    if(accounts.length != ids.length) revert InvalidCall();

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC165, IERC165) returns(bool) 
  {
    return
      interfaceId == type(IERC1155).interfaceId 
      || super.supportsInterface(interfaceId);
  }

  // ============ Approval Methods ============

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) 
    public virtual override 
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator) 
    public view virtual override returns(bool) 
  {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    if(owner == operator) revert InvalidCall();
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  // ============ Burn Methods ============

  /**
   * @dev Destroys `amount` tokens of token type `id` from `from`
   */
  function _burn(
    address from, 
    uint256 id, 
    uint256 amount
  ) internal virtual nonZeroAddress(from) {
    address operator = _msgSender();

    _beforeTokenTransfer(
      operator, 
      from, 
      address(0), 
      _asSingletonArray(id), 
      _asSingletonArray(amount), 
      ""
    );

    uint256 fromBalance = _balances[id][from];
    if (fromBalance < amount) revert InvalidCall();
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }

    emit TransferSingle(operator, from, address(0), id, amount);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
   */
  function _burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual nonZeroAddress(from) lengthMatches(ids, amounts) {
    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      if (fromBalance < amount) revert InvalidCall();
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
    }

    emit TransferBatch(operator, from, address(0), ids, amounts);
  }

  // ============ Mint Methods ============

  /**
   * @dev Creates `amount` tokens of token type `id`, and assigns 
   * them to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC1155Receiver-onERC1155Received} and return the
   *   acceptance magic value.
   */
  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual nonZeroAddress(to) {
    address operator = _msgSender();

    _beforeTokenTransfer(
      operator, 
      address(0), 
      to, 
      _asSingletonArray(id), 
      _asSingletonArray(amount), 
      data
    );

    _balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of 
   * {_mint}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC1155Receiver-onERC1155BatchReceived} and return the
   *   acceptance magic value.
   */
  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual nonZeroAddress(to) lengthMatches(ids, amounts) {
    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(
      operator, 
      address(0), 
      to, 
      ids, 
      amounts, 
      data
    );
  }

  // ============ Transfer Methods ============

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override isOwnerOrApproved(from) {
    _safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC1155Receiver-onERC1155Received} and return the
   *   acceptance magic value.
   */
  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual nonZeroAddress(to) {
    address operator = _msgSender();

    _beforeTokenTransfer(
      operator, 
      from, 
      to, 
      _asSingletonArray(id), 
      _asSingletonArray(amount), 
      data
    );

    uint256 fromBalance = _balances[id][from];
    if (fromBalance < amount) revert InvalidCall();
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override isOwnerOrApproved(from) {
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of 
   * {_safeTransferFrom}.
   */
  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual nonZeroAddress(to) lengthMatches(ids, amounts) {
    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      if (fromBalance < amount) revert InvalidCall();
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try IERC1155Receiver(to).onERC1155Received(
        operator, 
        from, 
        id, 
        amount, 
        data
      ) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try IERC1155Receiver(to).onERC1155BatchReceived(
        operator, 
        from, 
        ids, 
        amounts, 
        data
      ) returns (
        bytes4 response
      ) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `id` and `amount` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to 
   * xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  // ============ Internal Methods ============

  function _asSingletonArray(uint256 element) 
    private pure returns (uint256[] memory) 
  {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}
