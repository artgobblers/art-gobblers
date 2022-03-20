// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ArtGobblers} from "../ArtGobblers.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "./utils/mocks/VRFCoordinatorMock.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract OverflowTest is DSTestPlus {
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 constant ONE_THOUSAND_YEARS = 356 days * 1000;

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    VRFCoordinatorMock private vrfCoordinator;
    LinkToken private linkToken;

    Goop goop;
    Pages pages;

    bytes32 private keyHash;
    uint256 private fee;
    string private baseUri = "base";

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        gobblers = new ArtGobblers(address(vrfCoordinator), address(linkToken), keyHash, fee, baseUri);
        goop = gobblers.goop();
        pages = gobblers.pages();

        gobblers.setMerkleRoot("root");
    }

    ///////////////////////////////////////////////////////////////////////////

    // function testFindTooEarlyOverflowForLastGobbler() public {
    //     uint256 timeSinceStart = 500 days;
    //     while (true) {
    //         timeSinceStart -= 1 days;
    //         emit log_uint(timeSinceStart / 1 days);
    //         gobblers.getPrice(timeSinceStart, 7990);
    //     }
    // }

    // function testFindTooLateOverflowForLastGobbler() public {
    //     uint256 timeSinceStart = 500 days;
    //     while (true) {
    //         timeSinceStart += 1 days;
    //         emit log_uint(timeSinceStart / 1 days);
    //         gobblers.getPrice(timeSinceStart, 7990);
    //     }
    // }

    // function testFailOverflowTooEarlyForLastGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 0 days, 274 days), 7990);
    // }

    // function testFailOverflowTooLateForLastGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 1033 days, ONE_THOUSAND_YEARS), 7990);
    // }

    // function testSweetSpotForLastGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 275 days, 1032 days), 7990);
    // }

    ///////////////////////////////////////////////////////////////////////////

    // function testFindTooLateOverflowForFirstGobbler() public {
    //     uint256 timeSinceStart = 0 days;
    //     while (true) {
    //         timeSinceStart += 1 days;
    //         emit log_uint(timeSinceStart / 1 days);
    //         gobblers.getPrice(timeSinceStart, 0);
    //     }
    // }

    // function testFailOverflowTooLateForFirstGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 452 days, ONE_THOUSAND_YEARS), 0);
    // }

    // function testSweetSpotForFirstGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 0 days, 451 days), 0);
    // }

    ///////////////////////////////////////////////////////////////////////////

    // function testFindTooLateOverflowForMidGobbler() public {
    //     uint256 timeSinceStart = 0 days;
    //     while (true) {
    //         timeSinceStart += 1 days;
    //         emit log_uint(timeSinceStart / 1 days);
    //         gobblers.getPrice(timeSinceStart, 3395);
    //     }
    // }

    // function testFailOverflowTooLateForMidGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 507 days, ONE_THOUSAND_YEARS), 3395);
    // }

    // function testSweetSpotForMidGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 0 days, 506 days), 3395);
    // }

    ///////////////////////////////////////////////////////////////////////////

    // function testFindTooLateOverflowForUpperMidGobbler() public {
    //     uint256 timeSinceStart = 500 days;
    //     while (true) {
    //         timeSinceStart += 1 days;
    //         emit log_uint(timeSinceStart / 1 days);
    //         gobblers.getPrice(timeSinceStart, 6700);
    //     }
    // }

    // function testFailOverflowTooLateForUpperMidGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 598 days, ONE_THOUSAND_YEARS), 6700);
    // }

    // function testSweetSpotForUpperMidGobbler(uint256 timeSinceStart) public {
    //     gobblers.getPrice(bound(timeSinceStart, 0 days, 597 days), 6700);
    // }

    ///////////////////////////////////////////////////////////////////////////

    // function testSweetSpotForAllGobblers(uint256 timeSinceStart, uint256 id) public {
    //     gobblers.getPrice(bound(timeSinceStart, 275 days, 451 days), bound(id, 0, 7990));
    // }

    // function testFailOverflowTooLateForAllGobblers(uint256 timeSinceStart, uint256 id) public {
    //     gobblers.getPrice(bound(timeSinceStart, 1033 days, ONE_THOUSAND_YEARS), bound(id, 0, 7990));
    // }
}
