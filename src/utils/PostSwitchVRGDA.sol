// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "./VRGDA.sol";
import {unsafeWadDiv} from "./SignedWadMath.sol";

abstract contract PostSwitchVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable switchId; // todo: off by one?

    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable switchDay; // TODO: is it day or month?

    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable perDay; // tODO: is it per day?

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
            // TODO: is unchecked safe?
            // TODO? can the unsafeWadDiv be a constant? did i do this right? idt i did this right
            // TODO: how does this compare to linear VRGDA, can we derive one from other?
            return unsafeWadDiv(idWad - switchId, perDay) + switchDay;
        }
    }
}
