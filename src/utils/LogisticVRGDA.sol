// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "./VRGDA.sol";
import {wadExp, wadLn, unsafeDiv, unsafeWadDiv, toWad} from "./SignedWadMath.sol";

/// @title Logistic Variable Rate Gradual Dutch Auction
/// @notice Abstract VRGDA with a logistic issuance curve.
abstract contract LogisticVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @notice This parameter controls the logistic curve's maximum
    /// value, which controls the maximum number of NFTs to be issued.
    /// @dev Represented as a 36 decimal fixed point number.
    int256 private immutable logisticScale;

    /// @notice Time scale controls the steepness of the logistic curve, which
    /// effects the time period by which we want to reach the asymptote of the curve.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable timeScale;

    /// @notice The initial value the logistic formula would output.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable initialLogisticValue;

    constructor(int256 _logisticScale, int256 _timeScale) {
        // Because _logisticScale already comes in with 18
        // decimals, toWad will increase its decimals to 36.
        logisticScale = toWad(_logisticScale);

        timeScale = _timeScale;

        // Right shift by 1 is like dividing by 2.
        initialLogisticValue = _logisticScale >> 1;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    function getTargetSaleDay(int256 tokens) internal view virtual override returns (int256 day) {
        unchecked {
            return -unsafeWadDiv(wadLn(unsafeDiv(logisticScale, tokens + initialLogisticValue) - 1e18), timeScale);
        }
    }
}
