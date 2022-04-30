//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

library LibString {
    function toString(uint256 n) internal pure returns (string memory str) {
        if (n == 0) return "0";

        uint256 k = 78; // Will use to compute the length of the string.

        str = new string(k); // We'll over-allocate memory at first.

        assembly {
            // prettier-ignore
            // We'll populate string from right to left.
            for {} n {} { 
                // Write the current character into str.
                // The ASCII digit offset for '0' is 48.
                mstore(add(str, k), add(48, mod(n, 10)))

                k := sub(k, 1)
                n := div(n, 10)
            }

            // Shift the pointer to the start of the string.
            str := add(str, k)

            // Update to the length of the string in memory.
            mstore(str, sub(78, k))
        }
    }
}
