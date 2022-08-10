// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ArtGobblers} from "../src/ArtGobblers.sol";
import {Goo} from "../src/Goo.sol";
import {Pages} from "../src/Pages.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";
import {RandProvider} from "../src/utils/random/RandProviderInterface.sol";
import {ChainlinkV1RandProvider} from "../src/utils/random/ChainlinkV1RandProvider.sol";

contract VRGDAsTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 constant ONE_THOUSAND_YEARS = 356 days * 1000;

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    VRFCoordinatorMock private vrfCoordinator;
    LinkToken private linkToken;

    Goo goo;
    Pages pages;
    RandProvider randProvider;

    bytes32 private keyHash;
    uint256 private fee;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));

        //gobblers contract will be deployed after 2 contract deploys, and pages after 3
        address gobblerAddress = utils.predictContractAddress(address(this), 2);
        address pagesAddress = utils.predictContractAddress(address(this), 3);

        randProvider = new ChainlinkV1RandProvider(
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            ArtGobblers(gobblerAddress)
        );

        goo = new Goo(gobblerAddress, pagesAddress);

        gobblers = new ArtGobblers(
            "root",
            block.timestamp,
            goo,
            address(0xBEEF),
            address(0xBEEF),
            randProvider,
            "base",
            ""
        );

        pages = new Pages(block.timestamp, goo, address(0xBEEF), address(gobblers), "");
    }

    // function testFindGobblerOverflowPoint() public view {
    //     uint256 sold;
    //     while (true) {
    //         gobblers.getPrice(0 days, sold++);
    //     }
    // }

    // function testFindPagesOverflowPoint() public view {
    //     uint256 sold;
    //     while (true) {
    //         pages.getPrice(0 days, sold++);
    //     }
    // }

    function testNoOverflowForMostGobblers(uint256 timeSinceStart, uint256 sold) public {
        gobblers.getPrice(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS), bound(sold, 0, 1731));
    }

    function testNoOverflowForAllGobblers(uint256 timeSinceStart, uint256 sold) public {
        gobblers.getPrice(bound(timeSinceStart, 3870 days, ONE_THOUSAND_YEARS), bound(sold, 0, 6391));
    }

    function testFailOverflowForBeyondLimitGobblers(uint256 timeSinceStart, uint256 sold) public {
        gobblers.getPrice(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS), bound(sold, 6392, type(uint128).max));
    }

    function testGobblerPriceStrictlyIncreasesForMostGobblers() public {
        uint256 sold;
        uint256 previousPrice;

        while (sold <= 1731) {
            uint256 price = gobblers.getPrice(0 days, sold++);
            assertGt(price, previousPrice);
            previousPrice = price;
        }
    }

    function testNoOverflowForFirst8465Pages(uint256 timeSinceStart, uint256 sold) public {
        pages.getPrice(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS), bound(sold, 0, 8465));
    }

    function testPagePriceStrictlyIncreasesFor8465Pages() public {
        uint256 sold;
        uint256 previousPrice;

        while (sold <= 8465) {
            uint256 price = pages.getPrice(0 days, sold++);
            assertGt(price, previousPrice);
            previousPrice = price;
        }
    }
}
