// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {wadExp, wadLn, unsafeDiv, unsafeWadDiv} from "./SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";

/// @title Logistic Variable Rate Gradual Dutch Auction
/// @notice Abstract VRGDA with a logistic issuance curve.
abstract contract LogisticVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Controls the curve's maximum value which
    /// controls the maximum number of NFTs to be issued.
    /// @dev Represented as a 36 decimal fixed point number.
    int256 internal immutable logisticScale;

    /// @dev Time scale controls the steepness of the logistic curve,
    /// which effects how quickly we will reach the curve's asymptote.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable timeScale;

    /// @dev The initial value the uninverted logistic formula would output.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable initialLogisticValue;

    constructor(int256 _maxMintable, int256 _timeScale) {
        // We need to double _maxMintable to account for initialLogisticValue
        // and use 18 decimals to avoid wad multiplication in getTargetSaleDay.
        logisticScale = _maxMintable * 2e18;

        initialLogisticValue = _maxMintable;

        timeScale = _timeScale;
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
