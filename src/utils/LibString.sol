//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

library LibString {
    function toString(uint256 n) internal pure returns (string memory str) {
        if (n == 0) return "0";

        uint256 k = 78; // 78 is the max length a uint256 string could be.

        assembly {
            // Get a pointer to some free memory.
            str := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(str, and(add(add(78, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(str, 78)

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
