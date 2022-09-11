// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {Goo} from "../src/Goo.sol";
import {Pages} from "../src/Pages.sol";
import {ArtGobblers} from "../src/ArtGobblers.sol";
import {console} from "./utils/Console.sol";
import {fromDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

contract PagesTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;
    address payable[] internal users;
    address internal mintAuth;

    address internal user;
    Goo internal goo;
    Pages internal pages;
    uint256 mintStart;

    address internal community = address(0xBEEF);

    function setUp() public {
        // Avoid starting at timestamp at 0 for ease of testing.
        vm.warp(block.timestamp + 1);

        utils = new Utilities();
        users = utils.createUsers(5);

        goo = new Goo(
            // Gobblers:
            address(this),
            // Pages:
            utils.predictContractAddress(address(this), 1)
        );

        pages = new Pages(block.timestamp, goo, community, ArtGobblers(address(this)), "");

        user = users[1];
    }

    function testMintBeforeSetMint() public {
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(user);
        pages.mintFromGoo(type(uint256).max, false);
    }

    function testMintBeforeStart() public {
        vm.warp(block.timestamp - 1);

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(user);
        pages.mintFromGoo(type(uint256).max, false);
    }

    function testRegularMint() public {
        goo.mintForGobblers(user, pages.pagePrice());
        vm.prank(user);
        pages.mintFromGoo(type(uint256).max, false);
        assertEq(user, pages.ownerOf(1));
    }

    function testTargetPrice() public {
        // Warp to the target sale time so that the page price equals the target price.
        vm.warp(block.timestamp + fromDaysWadUnsafe(pages.getTargetSaleTime(1e18)));

        uint256 cost = pages.pagePrice();
        assertRelApproxEq(cost, uint256(pages.targetPrice()), 0.00001e18);
    }

    function testMintCommunityPagesFailsWithNoMints() public {
        vm.expectRevert(Pages.ReserveImbalance.selector);
        pages.mintCommunityPages(1);
    }

    function testCanMintCommunity() public {
        mintPageToAddress(user, 9);

        pages.mintCommunityPages(1);
        assertEq(pages.ownerOf(10), address(community));
    }

    function testCanMintMultipleCommunity() public {
        mintPageToAddress(user, 18);

        pages.mintCommunityPages(2);
        assertEq(pages.ownerOf(19), address(community));
        assertEq(pages.ownerOf(20), address(community));
    }

    function testCantMintTooFastCommunity() public {
        mintPageToAddress(user, 18);

        vm.expectRevert(Pages.ReserveImbalance.selector);
        pages.mintCommunityPages(3);
    }

    function testCantMintTooFastCommunityOneByOne() public {
        mintPageToAddress(user, 90);

        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);
        pages.mintCommunityPages(1);

        vm.expectRevert(Pages.ReserveImbalance.selector);
        pages.mintCommunityPages(1);
    }

    /// @notice Test that the pricing switch does now significantly slow down or speed up the issuance of pages.
    function testSwitchSmoothness() public {
        uint256 switchPageSaleTime = uint256(pages.getTargetSaleTime(8337e18) - pages.getTargetSaleTime(8336e18));

        assertRelApproxEq(
            uint256(pages.getTargetSaleTime(8336e18) - pages.getTargetSaleTime(8335e18)),
            switchPageSaleTime,
            0.0005e18
        );

        assertRelApproxEq(
            switchPageSaleTime,
            uint256(pages.getTargetSaleTime(8338e18) - pages.getTargetSaleTime(8337e18)),
            0.005e18
        );
    }

    /// @notice Test that page pricing matches expected behavior before switch.
    function testPagePricingPricingBeforeSwitch() public {
        // Expected sales rate according to mathematical formula.
        uint256 timeDelta = 60 days;
        uint256 numMint = 3572;

        vm.warp(block.timestamp + timeDelta);

        uint256 targetPrice = uint256(pages.targetPrice());

        for (uint256 i = 0; i < numMint; i++) {
            uint256 price = pages.pagePrice();
            goo.mintForGobblers(user, price);
            vm.prank(user);
            pages.mintFromGoo(price, false);
        }

        uint256 finalPrice = pages.pagePrice();

        // If selling at target rate, final price should equal starting price.
        assertRelApproxEq(targetPrice, finalPrice, 0.01e18);
    }

    /// @notice Test that page pricing matches expected behavior after switch.
    function testPagePricingPricingAfterSwitch() public {
        uint256 timeDelta = 360 days;
        uint256 numMint = 9479;

        vm.warp(block.timestamp + timeDelta);

        uint256 targetPrice = uint256(pages.targetPrice());

        for (uint256 i = 0; i < numMint; i++) {
            uint256 price = pages.pagePrice();
            goo.mintForGobblers(user, price);
            vm.prank(user);
            pages.mintFromGoo(price, false);
        }

        uint256 finalPrice = pages.pagePrice();

        // If selling at target rate, final price should equal starting price.
        assertRelApproxEq(finalPrice, targetPrice, 0.02e18);
    }

    function testInsufficientBalance() public {
        vm.prank(user);
        vm.expectRevert(stdError.arithmeticError);
        pages.mintFromGoo(type(uint256).max, false);
    }

    function testMintPriceExceededMax() public {
        uint256 cost = pages.pagePrice();
        goo.mintForGobblers(user, cost);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Pages.PriceExceededMax.selector, cost));
        pages.mintFromGoo(cost - 1, false);
    }

    /// @notice Mint a number of pages to the given address
    function mintPageToAddress(address addr, uint256 num) internal {
        for (uint256 i = 0; i < num; i++) {
            goo.mintForGobblers(addr, pages.pagePrice());

            vm.prank(addr);
            pages.mintFromGoo(type(uint256).max, false);
        }
    }
}
