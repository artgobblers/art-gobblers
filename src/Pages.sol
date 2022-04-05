// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

import {Goop} from "./Goop.sol";
import {PagePricer} from "./PagePricer.sol";

/// @notice Pages is an ERC721 that can hold drawn art.
contract Pages is ERC721("Pages", "PAGE"), PagePricer {
    using Strings for uint256;
    using PRBMathSD59x18 for int256;

    /// ----------------------------
    /// --------- State ------------
    /// ----------------------------

    /// @notice Id of last mint.
    uint256 internal currentId;

    /// @notice The number of pages minted from goop.
    uint256 internal numMintedFromGoop;

    /// @notice Base token URI.
    string internal constant BASE_URI = "";

    /// @notice Mapping from tokenId to isDrawn bool.
    mapping(uint256 => bool) public isDrawn;

    Goop internal goop;

    /// @notice Start of public mint.
    /// @dev Begins as type(uint256).max to pagePrice() underflow before minting starts.
    uint256 private mintStart = type(uint256).max;

    /// -----------------------
    /// ------ Authority ------
    /// -----------------------

    /// @notice User allowed to set the draw state on pages.
    address public immutable artist;

    /// @notice Authority to mint with 0 cost.
    address public immutable artGobblers;

    error Unauthorized();

    constructor(address _goop, address _artist) {
        goop = Goop(_goop);
        artist = _artist;
        artGobblers = msg.sender;
    }

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /// @notice Set whether a page is drawn.
    function setIsDrawn(uint256 tokenId) public only(artist) {
        isDrawn[tokenId] = true;
    }

    /// @notice Mint a page by burning goop.
    function mint() public {
        goop.burnForPages(msg.sender, getCurrentPrice());
        _mint(msg.sender, ++currentId);
        numMintedFromGoop++;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - mintStart; // This will revert if minting has not started yet.
        return pagePrice(timeSinceStart, numMintedFromGoop);
    }

    /// @notice Set mint start timestamp for regular minting.
    function setMintStart(uint256 _mintStart) public only(artGobblers) {
        mintStart = _mintStart;
    }

    /// @notice Mint by authority without paying mint cost.
    function mintByAuth(address addr) public only(artGobblers) {
        _mint(addr, ++currentId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId > currentId) return "";

        return string(abi.encodePacked(BASE_URI, tokenId.toString()));
    }
}
