// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {unsafeWadDiv} from "./SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";

/// @title "Post Switch" Variable Rate Gradual Dutch Auction
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice Abstract VRGDA with a (translated) linear issuance curve.
abstract contract PostSwitchVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev The number of tokens sold at the time of the switch.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable soldBySwitch;

    /// @dev The day soldBySwitch tokens were targeted to sell by.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable switchDay;

    /// @dev The total number of tokens to target selling each day.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable perDay;

    constructor(
        int256 _soldBySwitch,
        int256 _switchDay,
        int256 _perDay
    ) {
        soldBySwitch = _soldBySwitch;
        switchDay = _switchDay;
        perDay = _perDay;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    function getTargetSaleDay(int256 tokens) internal view virtual override returns (int256) {
        unchecked {
            return unsafeWadDiv(tokens - soldBySwitch, perDay) + switchDay;
        }
    }
}
