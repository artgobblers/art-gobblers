// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "./VRGDA.sol";
import {unsafeWadDiv} from "./SignedWadMath.sol";

abstract contract PostSwitchVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable switchId;

    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable switchDay;

    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable perDay;

    constructor(
        int256 _switchId,
        int256 _switchDay,
        int256 _perDay
    ) {
        switchId = _switchId;
        switchDay = _switchDay;
        perDay = _perDay;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    function getTargetSaleDay(int256 idWad) internal view virtual override returns (int256) {
        unchecked {
            return unsafeWadDiv(idWad - switchId, perDay) + switchDay;
        }
    }
}
