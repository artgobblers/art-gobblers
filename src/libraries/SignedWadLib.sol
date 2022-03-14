// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

library SignedWadLib {
    /// @dev Note: Takes an int256 but assumes it's positive.
    /// @dev Only returns positive numbers, uses int256 for convenience.
    function wadSqrt(int256 x) internal pure returns (int256 z) {
        assembly {
            // Scale x by 1e18 to keep the result accurate.
            // TODO: do we need overflow checks here?
            x := mul(x, 1000000000000000000)

            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    /// TODO: do we need to use SDIV?

    function mulWad(int256 x, int256 y) internal pure returns (int256 z) {
        assembly {
            // TODO: do we need overflow checks here?
            // Equivalent to require(x == 0 || (x * y) / x == y))
            // if iszero(or(iszero(x), eq(div(z, x), y))) {
            //     revert(0, 0)
            // }

            z := div(mul(x, y), 1000000000000000000)
        }
    }

    /// @dev Note: Will return 0 instead of reverting if y is zero.
    /// TODO: do we need to use SDIV?
    function divWad(int256 x, int256 y) internal pure returns (int256 z) {
        assembly {
            // TODO: do we need overflow checks here?
            // Equivalent to require(x == 0 || (x * y) / x == y))
            // if iszero(or(iszero(x), eq(div(z, x), y))) {
            //     revert(0, 0)
            // }

            z := div(mul(x, 1000000000000000000), y)
        }
    }
}
