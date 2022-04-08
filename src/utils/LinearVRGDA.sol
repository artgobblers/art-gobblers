// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "./VRGDA.sol";
import {unsafeWadDiv} from "./SignedWadMath.sol";

contract LinearVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @notice The target # of NFTs that should be sold each day.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable perDay;

    constructor(
        int256 _initialPrice,
        int256 periodPriceDecrease,
        int256 _perDay
    ) VRGDA(_initialPrice, periodPriceDecrease) {
        perDay = _perDay;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    function getTargetSaleDay(int256 idWad) internal view virtual override returns (int256) {
        return unsafeWadDiv(idWad, perDay);
    }
}
