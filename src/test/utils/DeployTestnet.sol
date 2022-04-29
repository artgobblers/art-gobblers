// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";

import {ERC1155BLockupVault} from "../../utils/ERC1155BLockupVault.sol";

import {Goop} from "../../Goop.sol";
import {Pages} from "../../Pages.sol";
import {ArtGobblers} from "../../ArtGobblers.sol";

import {LibRLP} from "./LibRLP.sol";

contract DeployTestnet {
    ERC1155BLockupVault public immutable team;

    VRFCoordinatorMock public immutable vrfCoordinator;

    ArtGobblers public immutable artGobblers;
    Pages public immutable pages;
    Goop public immutable goop;

    constructor(address linkToken) {
        vrfCoordinator = new VRFCoordinatorMock(linkToken);

        team = new ERC1155BLockupVault(address(this), 730 days);

        goop = new Goop(
            // Gobblers:
            LibRLP.computeAddress(address(this), 4), // TODO: THIS IS WRONG
            // Pages:
            LibRLP.computeAddress(address(this), 5)
        );

        artGobblers = new ArtGobblers(
            "root",
            block.timestamp,
            goop,
            address(team),
            address(vrfCoordinator),
            linkToken,
            0,
            0,
            "base://",
            "unrevealed"
        );

        pages = new Pages(block.timestamp, address(artGobblers), goop, "base://");
    }
}
