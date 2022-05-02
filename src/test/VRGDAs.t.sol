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
import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";

contract VRGDAsTest is DSTestPlus {
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

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));

        goop = new Goop(
            // Gobblers:
            utils.predictContractAddress(address(this), 1),
            // Pages:
            utils.predictContractAddress(address(this), 2)
        );

        gobblers = new ArtGobblers(
            "root",
            block.timestamp,
            goop,
            address(0xBEEF),
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            "base",
            ""
        );

        pages = new Pages(block.timestamp, address(gobblers), goop, "");
    }

    // function testFindGobblerOverflowPoint() public view {
    //     uint256 sold;
    //     while (true) {
    //         gobblers.getPrice(0 days, sold++);
    //     }
    // }

    // function testFindLastGobblerTooEarlyOverflowPoint() public {
    //     uint256 time = 999 days;
    //     while (true) {
    //         emit log_uint((time -= 1 days) / 1 days);
    //         gobblers.getPrice(time, 7191);
    //     }
    // }

    function testNoOverflowForMostGobblers(uint256 timeSinceStart, uint256 sold) public {
        gobblers.getPrice(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS), bound(sold, 0, 6756));
    }

    function testNoOverflowForAllGobblers(uint256 timeSinceStart, uint256 sold) public {
        gobblers.getPrice(bound(timeSinceStart, 437 days, ONE_THOUSAND_YEARS), bound(sold, 0, 7190));
    }

    function testFailOverflowForBeyondLimitGobblers(uint256 timeSinceStart, uint256 sold) public {
        gobblers.getPrice(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS), bound(sold, 7191, type(uint128).max));
    }

    function testGobblerPriceStrictlyIncreasesForMostGobblers() public {
        uint256 sold;
        uint256 previousPrice;

        while (sold <= 6756) {
            uint256 price = gobblers.getPrice(0 days, sold++);
            assertGt(price, previousPrice);
            previousPrice = price;
        }
    }

    function testNoOverflowForFirstTenThousandPages(uint256 timeSinceStart, uint256 sold) public {
        pages.getPrice(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS), bound(sold, 0, 10000));
    }

    function testGobblerPriceStrictlyIncreasesForTenThousandPages() public {
        uint256 sold;
        uint256 previousPrice;

        while (sold <= 10000) {
            uint256 price = pages.getPrice(0 days, sold++);
            assertGt(price, previousPrice);
            previousPrice = price;
        }
    }
}
