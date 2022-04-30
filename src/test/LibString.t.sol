// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {LibString} from "../utils/LibString.sol";

contract LibStringTest is DSTestPlus {
    function testTestToString(uint256 value) public {
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
