//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

library LibString {
    function toString(uint256 n) internal pure returns (string memory str) {
        if (n == 0) return "0";

        assembly {
            let k := 78 // Start with the max length a uint256 string could be.

            // We'll store our string at the first chunk of free memory.
            str := mload(0x40)

            // The length of our string will start off at the max of 78.
            mstore(str, k)

            // Update the free memory pointer to prevent overriding our string.
            // Add 128 to the str pointer instead of 78 because we want to maintain
            // the Solidity convention of keeping the free memory pointer word aligned.
            mstore(0x40, add(str, 128))

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

            // Set the length of the string to the correct value.
            mstore(str, sub(78, k))
        }
    }
}
