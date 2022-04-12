// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/stdlib.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";

contract PagesTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;
    address payable[] internal users;
    address internal mintAuth;
    address internal drawAuth;
    address internal user;
    Goop internal goop;
    Pages internal pages;
    uint256 mintStart;

    // encodings for expectRevert
    bytes unauthorized = abi.encodeWithSignature("Unauthorized()");
    bytes mintNotStarted = abi.encodeWithSignature("MintNotStarted()");

    function setUp() public {
        //avoid starting at timestamp = 0 for ease of testing
        vm.warp(block.timestamp + 1);

        utils = new Utilities();
        users = utils.createUsers(5);
        drawAuth = users[0];
        goop = new Goop(address(this));
        pages = new Pages(address(goop), drawAuth, block.timestamp);
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
        goop.mint(user, pages.pagePrice());
        vm.prank(user);
        pages.mint();
        assertEq(user, pages.ownerOf(1));
    }

    function testInitialPrice() public {
        uint256 cost = pages.pagePrice();
        uint256 maxDelta = 3780; // 0.00000000000000378

        assertApproxEq(cost, uint256(pages.initialPrice()), maxDelta);
    }

    function testInsufficientBalance() public {
        vm.prank(user);
        vm.expectRevert(stdError.arithmeticError);
        pages.mint();
    }

    function testSetIsDrawn() public {
        goop.mint(user, pages.pagePrice());
        vm.prank(user);
        pages.mint();
        assertTrue(!pages.isDrawn(1));
        vm.prank(drawAuth);
        pages.setIsDrawn(1);
        assertTrue(pages.isDrawn(1));
    }

    function testRevertSetIsDrawn() public {
        goop.mint(user, pages.pagePrice());
        vm.prank(user);
        pages.mint();
        vm.expectRevert(unauthorized);
        pages.setIsDrawn(1);
    }

    function mintPage(address _user) internal {
        goop.mint(_user, pages.pagePrice());
        vm.prank(_user);
        pages.mint();
    }
}
