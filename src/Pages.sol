// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

import {wadDiv} from "./utils/SignedWadMath.sol";
import {LogisticVRGDA} from "./utils/LogisticVRGDA.sol";

import {Goop} from "./Goop.sol";

/// @title Pages NFT (PAGE)
/// @notice Pages is an ERC721 that can hold drawn art.
contract Pages is ERC721("Pages", "PAGE"), LogisticVRGDA {
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

    /// ----------------------------
    /// ---- Pricing Parameters ----
    /// ----------------------------

    int256 private immutable perPeriodPostSwitchover = wadDiv(10e18, 3e18);

    int256 private immutable switchoverTime = 360e18;

    /// @notice Equal to 1 - periodPriceDecrease.
    int256 private immutable priceScaling = 0.75e18;

    /// @notice Number of pages sold before we switch pricing functions.
    uint256 private numPagesSwitch = 9975;

    /// @notice The start timestamp of the public mint.
    /// @dev Begins as type(uint256).max to force pagePrice() to underflow before minting starts.
    uint256 private mintStart = type(uint256).max;

    /// -----------------------
    /// ------ Authority ------
    /// -----------------------

    /// @notice User allowed to set the draw state on pages.
    address public immutable artist;

    /// @notice Authority to mint with 0 cost.
    address public immutable artGobblers;

    error Unauthorized();

    constructor(address _goop, address _artist)
        LogisticVRGDA(
            // Logistic scale. We multiply by 2x (as a wad)
            // to account for the subtracted initial value:
            10024e18, // TODO: did we ensure to make this 2x?
            // Time scale:
            wadDiv(1e18, 30e18),
            180e18, // Time shift.
            420e18, // Initial price.
            0.25e18 // Per period price decrease.
        )
    {
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
        uint256 price = pagePrice(); // This will revert if minting has not started yet.

        goop.burnForPages(msg.sender, price);

        unchecked {
            _mint(msg.sender, ++currentId);

            numMintedFromGoop++;
        }
    }

    /// @notice Set mint start timestamp for regular minting.
    function setMintStart(uint256 _mintStart) public only(artGobblers) {
        mintStart = _mintStart;
    }

    /// @notice Mint by authority without paying mint cost.
    function mintByAuth(address addr) public only(artGobblers) {
        unchecked {
            _mint(addr, ++currentId);
        }
    }

    /// @notice Calculate the mint cost of a page.
    /// @dev If the number of sales is below a pre-defined threshold, we use the
    /// VRGDA pricing algorithm, otherwise we use the post-switch pricing formula.
    /// @dev Reverts due to underflow if minting hasn't started yet. Done to save gas.
    function pagePrice() public view returns (uint256) {
        // We need checked math here to cause overflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        return
            (currentId < numPagesSwitch)
                ? getPrice(timeSinceStart, numMintedFromGoop)
                : postSwitchPrice(timeSinceStart);
    }

    /// @notice Calculate the mint cost of a page after the switch threshold.
    function postSwitchPrice(uint256 timeSinceStart) internal view returns (uint256) {
        // TODO: optimize this like we did in VRGDA.sol

        int256 fInv = (PRBMathSD59x18.fromInt(int256(numMintedFromGoop)) -
            PRBMathSD59x18.fromInt(int256(numPagesSwitch))).div(perPeriodPostSwitchover) + switchoverTime;

        // We convert seconds to days here, as we need to prevent overflow.
        int256 time = PRBMathSD59x18.fromInt(int256(timeSinceStart)).div(DAYS_WAD);

        int256 scalingFactor = priceScaling.pow(time - fInv); // This will always be positive.

        return uint256(initialPrice.mul(scalingFactor));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenId > currentId ? "" : string(abi.encodePacked(BASE_URI, tokenId.toString()));
    }
}
