// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {VRGDA} from "./VRGDA.sol";

import {Goop} from "./Goop.sol";

/// @notice Pages is an ERC721 that can hold art drawn
contract Pages is ERC721("Pages", "PAGE"), VRGDA {
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

    int256 private immutable logisticScale = PRBMathSD59x18.fromInt(10024);

    int256 private immutable timeScale = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(30));

    int256 private immutable timeShift = PRBMathSD59x18.fromInt(180);

    int256 private immutable initialPrice = PRBMathSD59x18.fromInt(420);

    int256 private immutable periodPriceDecrease = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(4));

    int256 private immutable perPeriodPostSwitchover = PRBMathSD59x18.fromInt(10).div(PRBMathSD59x18.fromInt(3));

    int256 private immutable switchoverTime = PRBMathSD59x18.fromInt(360);

    /// @notice Equal to 1 - periodPriceDecrease.
    int256 private immutable priceScaling = PRBMathSD59x18.fromInt(3).div(PRBMathSD59x18.fromInt(4));

    /// @notice Number of pages sold before we switch pricing functions.
    uint256 private numPagesSwitch = 9975;

    /// @notice Start of public mint.
    uint256 private mintStart;

    /// -----------------------
    /// ------ Authority ------
    /// -----------------------

    /// @notice Authority to set the draw state on pages.
    address public drawAddress;

    /// @notice Authority to mint with 0 cost.
    address public mintAddress;

    error Unauthorized();

    error MintNotStarted();

    constructor(address _goop, address _drawAddress)
        VRGDA(logisticScale, timeScale, timeShift, initialPrice, periodPriceDecrease)
    {
        goop = Goop(_goop);
        drawAddress = _drawAddress;

        // Deployer has mint authority.
        mintAddress = msg.sender;
    }

    /// @notice Requires sender address to match user address.
    modifier only(address user) {
        if (msg.sender != user) {
            revert Unauthorized();
        }
        _;
    }

    /// @notice Set whether a page is drawn.
    function setIsDrawn(uint256 tokenId) public only(drawAddress) {
        isDrawn[tokenId] = true;
    }

    /// @notice Mint a page by burning goop.
    function mint() public {
        // Mint start has not been set, or mint has not started.
        if (mintStart == 0 || block.timestamp < mintStart) revert MintNotStarted();

        uint256 price = pagePrice();

        goop.burnForPages(msg.sender, price);

        _mint(msg.sender, ++currentId);

        numMintedFromGoop++;
    }

    /// @notice Set mint start timestamp for regular minting.
    function setMintStart(uint256 _mintStart) public only(mintAddress) {
        mintStart = _mintStart;
    }

    /// @notice Mint by authority without paying mint cost.
    function mintByAuth(address addr) public only(mintAddress) {
        _mint(addr, ++currentId);
    }

    /// @notice Calculate the mint cost of a page.
    /// @dev If the number of sales is below a pre-defined threshold, we use the
    /// VRGDA pricing algorithm, otherwise we use the post-switch pricing formula.
    function pagePrice() public view returns (uint256) {
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
        int256 time = PRBMathSD59x18.fromInt(int256(timeSinceStart)).div(dayScaling);

        int256 scalingFactor = priceScaling.pow(time - fInv); // This will always be positive.

        return uint256(initialPrice.mul(scalingFactor));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId > currentId) return "";

        return string(abi.encodePacked(BASE_URI, tokenId.toString()));
    }
}
