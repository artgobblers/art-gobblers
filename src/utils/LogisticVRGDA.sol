// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "./VRGDA.sol";
import {wadExp, wadLn, wadMul, wadDiv, unsafeWadDiv} from "./SignedWadMath.sol";

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

    /// @notice Controls the time in which we reach the sigmoid's midpoint.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable timeShift;

    /// @notice The initial value the VRGDA logistic pricing formula would output.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable initialValue;

    constructor(
        int256 _logisticScale,
        int256 _timeScale,
        int256 _timeShift
    ) {
        logisticScale = _logisticScale;
        timeScale = _timeScale;
        timeShift = _timeShift;

        // TODO: can we use getTargetSaleDay? why is exp involved again?
        initialValue = wadDiv(logisticScale, 1e18 + wadExp(wadMul(timeScale, timeShift)));
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    function getTargetSaleDay(int256 idWad) internal view virtual override returns (int256) {
        unchecked {
            return timeShift + unsafeWadDiv(wadLn(unsafeWadDiv(logisticScale, idWad + initialValue) - 1e18), timeScale);
        }
    }
}
