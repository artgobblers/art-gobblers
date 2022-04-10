// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "./VRGDA.sol";
import {wadExp, wadLn, unsafeWadDiv} from "./SignedWadMath.sol";

// TODO: title and description for all the VRGDA stuff
abstract contract LogisticVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @notice This parameter controls the logistic curve's maximum
    /// value, which controls the maximum number of NFTs to be issued.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable logisticScale;

    /// @notice Time scale controls the steepness of the logistic curve, which
    /// effects the time period by which we want to reach the asymptote of the curve.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable timeScale;

    /// @notice The initial value the logistic formula would output.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable initialLogisticValue;

    constructor(int256 _logisticScale, int256 _timeScale) {
        logisticScale = _logisticScale;
        timeScale = _timeScale;

        initialLogisticValue = logisticScale / 2; // TODO: if we use this inline will it be a constant? do we even need this?
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    function getTargetSaleDay(int256 idWad) internal view virtual override returns (int256) {
        unchecked {
            return unsafeWadDiv(wadLn(unsafeWadDiv(logisticScale, idWad + initialLogisticValue) - 1e18), timeScale);
        }
    }
}
