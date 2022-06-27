// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/ArtGobblers.sol";

import {GobblerReserve} from "../src/utils/GobblerReserve.sol";

import {Goo} from "../src/Goo.sol";
import {Pages} from "../src/Pages.sol";
import {ArtGobblers} from "../src/ArtGobblers.sol";

import {LibRLP} from "../src/test/utils/LibRLP.sol";

abstract contract DeployBase is Script {
    //environment specific variables
    address private immutable teamColdWallet;
    bytes32 private immutable merkleRoot;
    uint256 private immutable mintStart;
    address private immutable vrfCoordinator; 


    //contract deploy nonces, used for address computation. Contract nonces start at 1.
    uint256 private immutable gobblerNonce = 5;
    uint256 private immutable pagesNonce = 6;

    constructor(
        address _teamColdWallet,
        bytes32 _merkleRoot, 
        uint256 _mintStart) {
        teamColdWallet = _teamColdWallet;
        merkleRoot = _merkleRoot;
        mintStart = _mintStart;
    }

    function run() external {   
        vm.startBroadcast();

        //deploy team and community reserves, owned by cold wallet.
        GobblerReserve teamReserve = new GobblerReserve(ArtGobblers(LibRLP.computeAddress(address(this), gobblerNonce)), teamColdWallet);
        GobblerReserve communityReserve = new GobblerReserve(ArtGobblers(LibRLP.computeAddress(address(this), gobblerNonce)), teamColdWallet);
        
        //deploy goo contract 
        Goo goo = new Goo(
            // Gobblers contract address
            LibRLP.computeAddress(address(this), gobblerNonce),
            // Pages contract address
            LibRLP.computeAddress(address(this), pagesNonce)
        );

        //deploy gobblers contract 
        ArtGobblers artGobblers = new ArtGobblers(
            merkleRoot,
            mintStart,
            goo,
            address(teamReserve),
            address(communityReserve),
            vrfCoordinator,
            linkToken,
            0,
            0,
            "base://",
            "unrevealed"
        );

        // pages = new Pages(block.timestamp, address(artGobblers), goo, "base://");

        vm.stopBroadcast();
    }
}
