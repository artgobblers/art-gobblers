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

// TODO: we should have custom ERC1155B for pages that has a custom isApprovedForAll function that always returns true for pages.
// TODO: ^ after we do that make sure to remove approvals in tests

/// @title Pages NFT (PAGE)
/// @notice Pages is an ERC721 that can hold drawn art.
contract Pages is ERC1155B, LogisticVRGDA, PostSwitchVRGDA {
    using Strings for uint256;
    using PRBMathSD59x18 for int256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    Goop internal goop; // todo: public?

    /*//////////////////////////////////////////////////////////////
                              URI CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Base token URI.
    string internal constant BASE_URI = "";

    /*//////////////////////////////////////////////////////////////
                              MINTING STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Id of last mint.
    uint256 internal currentId; // todo: public???

    /// @notice The number of pages minted from goop.
    uint256 internal numMintedFromGoop;

    /// @notice Timestamp for the start of the VRGDA mint.
    uint256 internal immutable mintStart;

    /*//////////////////////////////////////////////////////////////
                               DRAWN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from tokenId to isDrawn bool.
    mapping(uint256 => bool) public isDrawn;

    /*//////////////////////////////////////////////////////////////
                            PRICING CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice The id of the first page to be priced using the post switch VRGDA.
    /// @dev Computed by plugging the switch day into the uninverted pacing formula.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SWITCH_ID_WAD = 9830.311074899383736712e18;

    /*//////////////////////////////////////////////////////////////
                            AUTHORIZED USERS
    //////////////////////////////////////////////////////////////*/

    /// @notice User allowed to set the draw state on pages.
    address public immutable artist;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    constructor(
        address _goop,
        address _artist,
        uint256 _mintStart
    )
        VRGDA(
            4.20e18, // Initial price.
            0.31e18 // Per period price decrease.
        )
        LogisticVRGDA(
            // Logistic scale. We multiply by 2x (as a wad)
            // to account for the subtracted initial value,
            // and add 1 to ensure all the tokens can be sold:
            (9999 + 1) * 2e18,
            0.023e18 // Time scale.
        )
        PostSwitchVRGDA(
            SWITCH_ID_WAD, // Switch id.
            207e18, // Switch day.
            10e18 // Per day.
        )
    {
        goop = Goop(_goop);

        artist = _artist;

        mintStart = _mintStart;
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
    // TODO: do we still need this
    function setIsDrawn(uint256 tokenId) public only(artist) {
        isDrawn[tokenId] = true;
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    // TODO: do we want the ability to mint pages out of thin air for promotional reasons?

    /// @notice Mint a page by burning goop.
    function mint() public {
        // TODO: we could just transferFrom dont need special burn auth
        goop.burnForPages(msg.sender, pagePrice());

        unchecked {
            _mint(msg.sender, ++currentId, "");

            numMintedFromGoop++;
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

    function getTargetSaleDay(int256 idWad) internal view override(LogisticVRGDA, PostSwitchVRGDA) returns (int256) {
        return idWad < SWITCH_ID_WAD ? LogisticVRGDA.getTargetSaleDay(idWad) : PostSwitchVRGDA.getTargetSaleDay(idWad);
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenId > currentId ? "" : string(abi.encodePacked(BASE_URI, tokenId.toString()));
    }
}
