//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

// https://github.com/mzhu25/sol2string
library LibStrings {
    uint256 private constant MAX_UINT256_STRING_LENGTH = 78;
    uint8 private constant ASCII_DIGIT_OFFSET = 48;

    function toString(uint256 n) internal pure returns (string memory str) {
        if (n == 0) return "0"; // todo: can this be removed?

        // Overallocate memory
        str = new string(MAX_UINT256_STRING_LENGTH);
        uint256 k = MAX_UINT256_STRING_LENGTH;

        // Populate string from right to left (lsb to msb).
        while (n != 0) {
            assembly {
                let char := add(ASCII_DIGIT_OFFSET, mod(n, 10))
                mstore(add(str, k), char)
                k := sub(k, 1)
                n := div(n, 10)
            }
        }

        assembly {
            // Shift pointer over to actual start of string.
            str := add(str, k)
            // Store actual string length.
            mstore(str, sub(MAX_UINT256_STRING_LENGTH, k))
        }
    }
}
