// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";

import {GobblerReserve} from "../../utils/GobblerReserve.sol";

import {Goo} from "../../Goo.sol";
import {Pages} from "../../Pages.sol";
import {ArtGobblers} from "../../ArtGobblers.sol";

import {LibRLP} from "./LibRLP.sol";

contract DeployTestnet {
    // Ensures forge does not complain
    // about the size of this contract.
    bool public constant IS_TEST = true;

    GobblerReserve public immutable team;
    GobblerReserve public immutable community;

    VRFCoordinatorMock public immutable vrfCoordinator;

    ArtGobblers public immutable artGobblers;
    Pages public immutable pages;
    Goo public immutable goo;

    constructor(address linkToken) {
        vrfCoordinator = new VRFCoordinatorMock(linkToken);

        team = new GobblerReserve(ArtGobblers(LibRLP.computeAddress(address(this), 5)), address(this));
        community = new GobblerReserve(ArtGobblers(LibRLP.computeAddress(address(this), 5)), address(this));

        goo = new Goo(
            // Gobblers (contract nonces start at 1):
            LibRLP.computeAddress(address(this), 5),
            // Pages (contract nonces start at 1):
            LibRLP.computeAddress(address(this), 6)
        );

        artGobblers = new ArtGobblers(
            "root",
            block.timestamp,
            goo,
            address(team),
            address(community),
            address(vrfCoordinator),
            linkToken,
            0,
            0,
            "base://",
            "unrevealed"
        );

        pages = new Pages(block.timestamp, address(artGobblers), goo, "base://");
    }
}
