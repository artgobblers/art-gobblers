// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";

import {ArtGobblers} from "../../src/ArtGobblers.sol";

contract MintFromMintlist is Script {
    // Art Gobblers address on network we want to run script for.
    ArtGobblers public gobblers = ArtGobblers(0x60Bb1E329d8f783D55fECB1E8d748838753fF169);

    function run() external {
        //address is in merkle root
        address minter = 0x7eD52863829AB99354F3a0503A622e82AcD5F7d3;

        console.logBytes32((keccak256(abi.encodePacked(minter))));

        //merkle proof
        bytes32[] memory proof = new bytes32[](11);
        proof[0] = 0x626dd9764069fe93a63704a0410fd234fd5760aae273422589229a84407dd907;
        proof[1] = 0x15cddc2d3e2eb1a26363fe4d0f66ca53be6cc8287f4b9d04315d304998fade5d;
        proof[2] = 0x7e45736281f828403590f310425f09450fd29323d32c863cf578dec124f29eb3;
        proof[3] = 0x408e05c119de24031022161ef807ce73495a56e5033d2c4a8f1ec64a98315a63;
        proof[4] = 0x583aa04f96de94308b1c0f26cb1d890eac12b3ce217b03772f7419da6370da19;
        proof[5] = 0x168278c617162f7263cafbc1829105eacfb5f0d5b23b966deeb91b47862bf73d;
        proof[6] = 0x16602110573b4588e91787f90fffb40d22026145c16fd6ff3dd398482c1bb06a;
        proof[7] = 0x602d52ecc3571462472dea9a6eaea65e0774e5a7c7d6c35b2336fe70e1fa8acb;
        proof[8] = 0x09db3d3d14ec5fab971ab460eb01e96f28b125c7b365c28a1fb317f4c6e3ec8b;
        proof[9] = 0x2b3cefd21e863e1f72e6af4f8b9f33787fba3ae9b2e5641e1954d474b6091914;
        proof[10] = 0xde217e6711a1efa1fb72a7cdb2f6f352523f700cffccd09f0bdac0a79c8381fe;

        vm.startBroadcast();
        gobblers.claimGobbler(proof);
        vm.stopBroadcast();
    }
}
