// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721StaticTokenURI is ERC721, IERC721Metadata {
  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual returns(string memory) {
    return staticTokenURI(tokenId);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function staticTokenURI(
    uint256 tokenId
  ) public view virtual isToken(tokenId) returns(string memory) {
    return _tokenURIs[tokenId];
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   */
  function _setTokenURI(
    uint256 tokenId, 
    string memory uri
  ) internal virtual isToken(tokenId) {
    _tokenURIs[tokenId] = uri;
  }
}
