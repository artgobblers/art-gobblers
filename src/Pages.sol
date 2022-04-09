// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

import {VRGDA} from "./utils/VRGDA.sol";
import {ERC1155B} from "./utils/ERC1155B.sol";
import {wadDiv} from "./utils/SignedWadMath.sol";
import {LogisticVRGDA} from "./utils/LogisticVRGDA.sol";
import {PostSwitchVRGDA} from "./utils/PostSwitchVRGDA.sol";

import {Goop} from "./Goop.sol";

/// @title Pages NFT (PAGE)
/// @notice Pages is an ERC721 that can hold drawn art.
contract Pages is ERC1155B, LogisticVRGDA, PostSwitchVRGDA {
    using Strings for uint256;
    using PRBMathSD59x18 for int256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    Goop internal goop;

    /*//////////////////////////////////////////////////////////////
                              URI CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Base token URI.
    string internal constant BASE_URI = "";

    /*//////////////////////////////////////////////////////////////
                              MINTING STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Id of last mint.
    uint256 internal currentId;

    /// @notice The number of pages minted from goop.
    uint256 internal numMintedFromGoop;

    /// @notice The start timestamp of the public mint.
    /// @dev Begins as type(uint256).max to force pagePrice() to underflow before minting starts.
    uint256 internal mintStart = type(uint256).max;

    /*//////////////////////////////////////////////////////////////
                               DRAWN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from tokenId to isDrawn bool.
    mapping(uint256 => bool) public isDrawn;

    /*//////////////////////////////////////////////////////////////
                            PRICING CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // TODO: do we make this stuff and the above public?

    /// @notice The id of the first page to be priced using the post switch VRGDA.
    uint256 internal constant SWITCH_ID = 9975;

    /*//////////////////////////////////////////////////////////////
                            AUTHORIZED USERS
    //////////////////////////////////////////////////////////////*/

    /// @notice User allowed to set the draw state on pages.
    address public immutable artist;

    /// @notice Authority to mint with 0 cost.
    address public immutable artGobblers;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    constructor(address _goop, address _artist)
        VRGDA(
            420e18, // Initial price.
            0.25e18 // Per period price decrease.
        )
        LogisticVRGDA(
            // Logistic scale. We multiply by 2x (as a wad)
            // to account for the subtracted initial value:
            10024e18, // TODO: did we ensure to make this 2x?
            wadDiv(1e18, 30e18), // Time scale.
            0 // Time shift. // TODO: update these values
        )
        PostSwitchVRGDA(
            int256(SWITCH_ID), // Switch id.
            360e18, // Switch day. // TODO: why do we have day and id?
            wadDiv(10e18, 3e18) // Per day.
        )
    {
        goop = Goop(_goop);
        artist = _artist;
        artGobblers = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                           CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /// @notice Set whether a page is drawn.
    function setIsDrawn(uint256 tokenId) public only(artist) {
        isDrawn[tokenId] = true;
    }

    /// @notice Set mint start timestamp for regular minting.
    function setMintStart(uint256 _mintStart) public only(artGobblers) {
        mintStart = _mintStart;
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a page by burning goop.
    function mint() public {
        uint256 price = pagePrice(); // This will revert if minting has not started yet.

        goop.burnForPages(msg.sender, price);

        unchecked {
            _mint(msg.sender, ++currentId, "");

            numMintedFromGoop++;
        }
    }

    /// @notice Mint by authority without paying mint cost.
    function mintByAuth(address addr) public only(artGobblers) {
        unchecked {
            _mint(addr, ++currentId, "");
        }
    }

    /*//////////////////////////////////////////////////////////////
                           VRGDA PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the mint cost of a page.
    /// @dev If the number of sales is below a pre-defined threshold, we use the
    /// VRGDA pricing algorithm, otherwise we use the post-switch pricing formula.
    /// @dev Reverts due to underflow if minting hasn't started yet. Done to save gas.
    function pagePrice() public view returns (uint256) {
        // We need checked math here to cause overflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        return getPrice(timeSinceStart, numMintedFromGoop);
    }

    // TODO: should we be more strict about only using ints where we need them?
    function getTargetSaleDay(int256 idWad) internal view override(LogisticVRGDA, PostSwitchVRGDA) returns (int256) {
        return currentId < SWITCH_ID ? LogisticVRGDA.getTargetSaleDay(idWad) : PostSwitchVRGDA.getTargetSaleDay(idWad);
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenId > currentId ? "" : string(abi.encodePacked(BASE_URI, tokenId.toString()));
    }
}
