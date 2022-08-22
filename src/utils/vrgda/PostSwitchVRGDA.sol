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
    /// @param _soldBySwitch The number of tokens sold at the time of the switch, scaled by 1e18.
    /// @param _switchDay The day soldBySwitch tokens were targeted to sell by, scaled by 1e18.
    /// @param _perDay The total number of tokens to target selling each day, scaled by 1e18.
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

    /// @dev Given a number of tokens sold, return the target day that number of tokens should be sold by.
    /// @dev Note: Assumes this function is only called when sold > soldBySwitch, otherwise it will underflow.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale day for.
    /// @return The target day the tokens should be sold by, scaled by 1e18, where the day is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleDay(int256 sold) public view virtual override returns (int256) {
        unchecked {
            return unsafeWadDiv(sold - soldBySwitch, perDay) + switchDay;
        }
    }
}
