// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";
import {console} from "./utils/Console.sol";

contract PagesTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;
    address payable[] internal users;
    address internal mintAuth;

    address internal user;
    Goop internal goop;
    Pages internal pages;
    uint256 mintStart;

    function setUp() public {
        // avoid starting at timestamp = 0 for ease of testing
        vm.warp(block.timestamp + 1);

        utils = new Utilities();
        users = utils.createUsers(5);

        goop = new Goop(
            // Gobblers:
            address(this),
            // Pages:
            utils.predictContractAddress(address(this), 1)
        );

        pages = new Pages(block.timestamp, address(this), goop, "");

        user = users[1];
    }

    function testMintBeforeSetMint() public {
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(user);
        pages.mintFromGoop(type(uint256).max);
    }

    function testMintBeforeStart() public {
        vm.warp(block.timestamp - 1);

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(user);
        pages.mintFromGoop(type(uint256).max);
    }

    function testRegularMint() public {
        goop.mintForGobblers(user, pages.pagePrice());
        vm.prank(user);
        pages.mintFromGoop(type(uint256).max);
        assertEq(user, pages.ownerOf(1));
    }

    function testInitialPrice() public {
        uint256 cost = pages.pagePrice();
        uint256 maxDelta = 5; // 0.000000000000000005

        assertApproxEq(cost, uint256(pages.initialPrice()), maxDelta);
    }

    //test that page pricing matches expected behaviour before switch
    function testPagePricingPricingBeforeSwitch() public {
        //expected sales rate according to mathematical formula
        uint256 timeDelta = 60 days;
        uint256 numMint = 5979;

        vm.warp(block.timestamp + timeDelta);

        uint256 initialPrice = uint256(pages.initialPrice());

        for (uint256 i = 0; i < numMint; i++) {
            uint256 price = pages.pagePrice();
            goop.mintForGobblers(user, price);
            vm.prank(user);
            pages.mintFromGoop(price);
        }

        uint256 finalPrice = pages.pagePrice();
        //if selling at target rate, final price should equal starting price
        assertRelApproxEq(initialPrice, finalPrice, 0.01e18);
    }

    //test that page pricing matches expected behaviour before switch
    function testPagePricingPricingAfterSwitch() public {
        uint256 timeDelta = 360 days;
        uint256 numMint = 11359;

        vm.warp(block.timestamp + timeDelta);

        uint256 initialPrice = uint256(pages.initialPrice());

        for (uint256 i = 0; i < numMint; i++) {
            uint256 price = pages.pagePrice();
            goop.mintForGobblers(user, price);
            vm.prank(user);
            pages.mintFromGoop(price);
        }

        uint256 finalPrice = pages.pagePrice();
        //if selling at target rate, final price should equal starting price
        assertRelApproxEq(initialPrice, finalPrice, 0.02e18);
    }

    function testInsufficientBalance() public {
        vm.prank(user);
        vm.expectRevert(stdError.arithmeticError);
        pages.mintFromGoop(type(uint256).max);
    }

    function testMintPriceExceededMax() public {
        uint256 cost = pages.pagePrice();
        goop.mintForGobblers(user, cost);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Pages.PriceExceededMax.selector, cost, cost - 1));
        pages.mintFromGoop(cost - 1);
    }

    function mintPage(address _user) internal {
        goop.mintForGobblers(_user, pages.pagePrice());
        vm.prank(_user);
        pages.mintFromGoop(type(uint256).max);
    }
}
