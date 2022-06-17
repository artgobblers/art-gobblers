// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {FixedPointMathLib as Math} from "solmate/utils/FixedPointMathLib.sol";

contract MockGoopCalculator {
    /// @notice Compute goo balance based on emission multiple, last balance, and days
    /// @dev Must be kept up to date with the gooBalance function's corresponding emission balance calculations in ArtGobblers.sol.
    /// @dev Forked from https://github.com/FrankieIsLost/art-gobblers/blob/807809821c615ec46b7f42e838346c5c57a402f6/src/ArtGobblers.sol#L579-L595
    function computeGoopBalance(
        uint256 emissionMultiple,
        uint256 lastBalanceWad,
        uint256 daysElapsedWad
    ) public pure returns (uint256) {
        unchecked {
            uint256 daysElapsedSquaredWad = Math.mulWadDown(daysElapsedWad, daysElapsedWad); // Need to use wad math here.

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.

            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * daysElapsedSquaredWad) >> 2) +

            Math.mulWadDown(
                daysElapsedWad, // Must mulWad because both terms are wads.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                Math.sqrt(emissionMultiple * lastBalanceWad * 1e18)
            );
        }
    }
}
