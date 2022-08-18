// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadLn, unsafeDiv, unsafeWadDiv} from "../lib/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";

/// @title Logistic Variable Rate Gradual Dutch Auction
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice Abstract VRGDA with a logistic issuance curve.
abstract contract LogisticVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Controls the curve's maximum value which
    /// controls the maximum number of tokens to sell.
    /// @dev Represented as a 36 decimal fixed point number.
    int256 internal immutable logisticScale;

    /// @dev Time scale controls the steepness of the logistic curve,
    /// which affects how quickly we will reach the curve's asymptote.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable timeScale;

    /// @dev The initial value the uninverted logistic formula would output.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable initialLogisticValue;

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _maxMintable The maximum number of tokens that can be minted.
    /// @param _timeScale The steepness of the logistic curve.
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

    /// @dev Given a number of tokens sold, return the target day that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale day for.
    /// @return The target day the tokens should be sold by, scaled by 1e18, where the day is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleDay(int256 sold) internal view virtual override returns (int256) {
        unchecked {
            return -unsafeWadDiv(wadLn(unsafeDiv(logisticScale, sold + initialLogisticValue) - 1e18), timeScale);
        }
    }
}
