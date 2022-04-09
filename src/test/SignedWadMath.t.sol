// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {wadMul, wadDiv} from "../utils/SignedWadMath.sol";

contract SignedWadMathTest is DSTestPlus {
    function testWadMul(int256 x, int256 y) public {
        // Ignore cases where x * y overflows.
        unchecked {
            if ((x != 0 && (x * y) / x != y)) return;
        }

        assertEq(wadMul(x, y), (x * y) / 1e18);
    }

    function testFailWadMulOverflow(int256 x, int256 y) public pure {
        // Ignore cases where x * y does not overflow.
        unchecked {
            if ((x * y) / x == y) revert();
        }

        wadMul(x, y);
    }

    function testWadDiv(int256 x, int256 y) public {
        // Ignore cases where x * WAD overflows or y is 0.
        unchecked {
            if (y == 0 || (x != 0 && (x * 1e18) / 1e18 != x)) return;
        }

        assertEq(wadDiv(x, y), (x * 1e18) / y);
    }

    function testFailWadDivOverflow(int256 x, int256 y) public pure {
        // Ignore cases where x * WAD does not overflow or y is 0.
        unchecked {
            if (y == 0 || (x * 1e18) / 1e18 == x) revert();
        }

        wadDiv(x, y);
    }

    function testFailWadDivZeroDenominator(int256 x) public pure {
        wadDiv(x, 0);
    }
}
