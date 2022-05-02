// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {LibString} from "../utils/LibString.sol";

contract LibStringTest is DSTestPlus {
    function testToString() public {
        assertEq(LibString.toString(0), "0");
        assertEq(LibString.toString(1), "1");
        assertEq(LibString.toString(17), "17");
        assertEq(LibString.toString(99999999), "99999999");
        assertEq(LibString.toString(99999999999), "99999999999");
        assertEq(LibString.toString(2342343923423), "2342343923423");
        assertEq(LibString.toString(98765685434567), "98765685434567");
    }

    function testDifferentiallyFuzzToString(uint256 value, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        string memory libString = LibString.toString(value);
        string memory oz = toStringOZ(value);

        assertEq(bytes(libString).length, bytes(oz).length);
        assertEq(libString, oz);
    }
}

function toStringOZ(uint256 value) pure returns (string memory) {
    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
}
