// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Strings} from "openzeppelin/utils/Strings.sol";

import {VRGDA} from "./utils/VRGDA.sol";
import {PagesERC1155B} from "./utils/PagesERC1155B.sol";
import {LogisticVRGDA} from "./utils/LogisticVRGDA.sol";
import {PostSwitchVRGDA} from "./utils/PostSwitchVRGDA.sol";

import {Goop} from "./Goop.sol";
import {ArtGobblers} from "./ArtGobblers.sol";

// todo: events?

/// @title Pages NFT
/// @notice Pages is an ERC721 that can hold drawn art.
contract Pages is PagesERC1155B, LogisticVRGDA, PostSwitchVRGDA {
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    Goop public goop; // todo: public?

    /*//////////////////////////////////////////////////////////////
                              URI CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Base token URI.
    string public BASE_URI = "";

    // TODO ^^ take this via a constructor arg

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of the VRGDA mint.
    uint256 public immutable mintStart;

    /// @notice The number of pages minted from goop.
    uint128 public numMintedFromGoop;

    /*//////////////////////////////////////////////////////////////
                              MINTING STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Id of the current page.
    uint128 public currentId;

    /*//////////////////////////////////////////////////////////////
                            PRICING CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The day the switch from a logistic to translated linear VRGDA is targeted to occur.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SWITCH_DAY_WAD = 207e18;

    /// @notice The id of the first page to be priced using the post switch VRGDA.
    /// @dev Computed by plugging the switch day into the uninverted pacing formula.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SWITCH_ID_WAD = 9829.328043791893798338e18;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error PriceExceededMax(uint256 currentPrice, uint256 maxPrice);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        uint256 _mintStart,
        address _artGobblers,
        Goop _goop
    )
        VRGDA(
            4.20e18, // Initial price.
            0.31e18 // Per period price decrease.
        )
        LogisticVRGDA(
            9999e18, // Asymptote.
            0.023e18 // Time scale.
        )
        PostSwitchVRGDA(
            SWITCH_ID_WAD, // Switch id.
            SWITCH_DAY_WAD, // Switch day.
            10e18 // Pages to target per day.
        )
        PagesERC1155B(_artGobblers)
    {
        mintStart = _mintStart;

        goop = _goop;
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a page with goop, burning the cost.
    /// @param maxPrice Maximum price to pay to mint the gobbler.
    /// @return pageId The id of the page that was minted.
    function mintFromGoop(uint256 maxPrice) public returns (uint256 pageId) {
        // Will revert if prior to mint start.
        uint256 currentPrice = pagePrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice, maxPrice);

        goop.burnForPages(msg.sender, currentPrice);

        unchecked {
            ++numMintedFromGoop; // Before mint to prevent reentrancy.

            _mint(msg.sender, pageId = ++currentId, "");
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

        return getPrice(timeSinceStart, numMintedFromGoop);
    }

    function getTargetSaleDay(int256 idWad) internal view override(LogisticVRGDA, PostSwitchVRGDA) returns (int256) {
        return idWad < SWITCH_ID_WAD ? LogisticVRGDA.getTargetSaleDay(idWad) : PostSwitchVRGDA.getTargetSaleDay(idWad);
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 pageId) public view virtual override returns (string memory) {
        if (pageId > currentId) return "";

        return string(abi.encodePacked(BASE_URI, pageId.toString()));
    }
}
