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
import {MockVRFCoordinatorV2} from "./utils/mocks/MockVRFCoordinatorV2.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract VRGDAsTest is DSTestPlus {
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 constant ONE_THOUSAND_YEARS = 356 days * 1000;

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    MockVRFCoordinatorV2 private vrfCoordinator;
    LinkToken private linkToken;
    Goop goop;
    Pages pages;

    uint96 constant FUND_AMOUNT = 1 * 10**18;

    // Initialized as blank, fine for testing
    uint64 subId;
    bytes32 keyHash; // gasLane

    string private baseUri = "base";

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new MockVRFCoordinatorV2();
        subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);

        gobblers = new ArtGobblers("root", block.timestamp, address(vrfCoordinator), keyHash, subId, baseUri);
        goop = gobblers.goop();
        pages = gobblers.pages();
    }

    // TODO: this rly isnt an id its cummulative sold
    function testNoOverflowForAllGobblers(uint256 timeSinceStart, uint256 id) public {
        gobblers.getPrice(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS), bound(id, 0, 7990));
    }

    function testNoOverflowForFirstTenThousandPages(uint256 timeSinceStart, uint256 id) public {
        pages.getPrice(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS), bound(id, 0, 10000));
    }
}
