// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract MockGooCalculator {
    using FixedPointMathLib for uint256;

    /// @notice Compute goo balance based on emission multiple, last balance, and days elapsed.
    /// @dev Must be kept up to date with the gooBalance function's corresponding emission balance calculations in ArtGobblers.sol.
    /// @dev Forked from https://github.com/artgobblers/art-gobblers/blob/2f19bc901ed2f1bfedeb6f113b073bfc3585386a/src/ArtGobblers.sol#L693-L708
    function computeGooBalance(
        uint256 emissionMultiple,
        uint256 lastBalanceWad,
        uint256 daysElapsedWad
    ) public pure returns (uint256) {
        unchecked {
            uint256 daysElapsedSquaredWad = daysElapsedWad.mulWadDown(daysElapsedWad); // Need to use wad math here.

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.

            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * daysElapsedSquaredWad) >> 2) +

            daysElapsedWad.mulWadDown( // Terms are wads, so must mulWad.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                (emissionMultiple * lastBalanceWad * 1e18).sqrt()
            );
        }
    }
}
