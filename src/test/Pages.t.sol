// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";

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

        goop = new Goop(address(this));
        pages = new Pages(block.timestamp, goop);
        // Deploying contract is mint authority
        mintAuth = address(this);
        goop.setPages(address(pages));
        user = users[1];
    }

    function testMintBeforeSetMint() public {
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(user);
        pages.mint();
    }

    function testMintBeforeStart() public {
        vm.warp(block.timestamp - 1);

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(user);
        pages.mint();
    }

    function testRegularMint() public {
        goop.mintForGobblers(user, pages.pagePrice());
        vm.prank(user);
        pages.mint();
        assertEq(user, pages.ownerOf(1));
    }

    function testInitialPrice() public {
        uint256 cost = pages.pagePrice();
        uint256 maxDelta = 5; // 0.000000000000000005

        assertApproxEq(cost, uint256(pages.initialPrice()), maxDelta);
    }

    function testInsufficientBalance() public {
        vm.prank(user);
        vm.expectRevert(stdError.arithmeticError);
        pages.mint();
    }

    function mintPage(address _user) internal {
        goop.mintForGobblers(_user, pages.pagePrice());
        vm.prank(_user);
        pages.mint();
    }
}
