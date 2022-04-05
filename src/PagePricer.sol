// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "./VRGDA.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

/// @notice Pages is an ERC721 that can hold drawn art.
contract PagePricer is VRGDA {
    using PRBMathSD59x18 for int256;

    int256 public immutable initialPrice = PRBMathSD59x18.fromInt(420);

    int256 private immutable logisticScale = PRBMathSD59x18.fromInt(10024);

    int256 private immutable timeScale = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(30));

    int256 private immutable timeShift = PRBMathSD59x18.fromInt(180);

    int256 private immutable periodPriceDecrease = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(4));

    int256 private immutable perPeriodPostSwitchover = PRBMathSD59x18.fromInt(10).div(PRBMathSD59x18.fromInt(3));

    int256 private immutable switchoverTime = PRBMathSD59x18.fromInt(360);

    /// @notice Equal to 1 - periodPriceDecrease.
    int256 private immutable priceScaling = PRBMathSD59x18.fromInt(3).div(PRBMathSD59x18.fromInt(4));

    /// @notice Number of pages sold before we switch pricing functions.
    uint256 private numPagesSwitch = 9975;

    constructor() VRGDA(logisticScale, timeScale, timeShift, initialPrice, periodPriceDecrease) {}

    /// @notice Calculate the price according to modified VRGDA
    /// @param timeSinceStart The time since the initial sale, in seconds.
    /// @param numMinted The token id to get the price of at the current time.
    function pagePrice(uint256 timeSinceStart, uint256 numMinted) public view returns (uint256) {
        return
            (numMinted < numPagesSwitch)
                ? getPrice(timeSinceStart, numMinted)
                : postSwitchPrice(timeSinceStart, numMinted);
    }

    /// @notice Calculate the mint cost of a page after the switch threshold.
    function postSwitchPrice(uint256 timeSinceStart, uint256 numMinted) internal view returns (uint256) {
        // TODO: optimize this like we did in VRGDA.sol

        int256 fInv = (PRBMathSD59x18.fromInt(int256(numMinted)) - PRBMathSD59x18.fromInt(int256(numPagesSwitch))).div(
            perPeriodPostSwitchover
        ) + switchoverTime;

        // We convert seconds to days here, as we need to prevent overflow.
        int256 time = PRBMathSD59x18.fromInt(int256(timeSinceStart)).div(dayScaling);

        int256 scalingFactor = priceScaling.pow(time - fInv); // This will always be positive.

        return uint256(initialPrice.mul(scalingFactor));
    }
}
