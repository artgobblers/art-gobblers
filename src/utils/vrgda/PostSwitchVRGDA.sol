// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {unsafeWadDiv} from "../lib/SignedWadMath.sol";

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

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _soldBySwitch The number of tokens sold at the time of the switch.
    /// @param _switchDay The day soldBySwitch tokens were targeted to sell by.
    /// @param _perDay The total number of tokens to target selling each day.
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

    /// @dev Given the number of tokens sold so far, return the target day the next token should be sold by.
    /// @param sold The number of tokens that have been sold so far, where 0 means none, scaled by 1e18.
    /// @return The target day that the next token should be sold by, scaled by 1e18, where the day
    /// is relative, such that 0 means the token should be sold immediately when the VRGDA begins.
    function getTargetDayForNextSale(int256 sold) internal view virtual override returns (int256) {
        unchecked {
            return unsafeWadDiv(sold - soldBySwitch, perDay) + switchDay;
        }
    }
}
