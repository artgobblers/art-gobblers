// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";

contract PagesTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;
    address payable[] internal users;
    address internal owner;
    address internal minter;
    Goop internal goop;
    Pages internal pages;

    //encodings for expectRevert
    bytes insufficientBalance =
        abi.encodeWithSignature("InsufficientBalance()");

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        owner = users[0];
        minter = users[1];
        goop = new Goop(address(this));
        pages = new Pages(address(goop), owner);
        goop.setPages(address(pages));
    }

    function testPageMint() public {
        goop.mint(minter, pages.MINT_COST());
        vm.prank(minter);
        pages.mint();
        assertEq(minter, pages.ownerOf(1));
    }

    function testInsufficientBalance() public {
        goop.mint(minter, pages.MINT_COST() - 1);
        vm.expectRevert(insufficientBalance);
        vm.prank(minter);
        pages.mint();
    }

    function testSetIsDrawn() public {
        goop.mint(minter, pages.MINT_COST());
        vm.prank(minter);
        pages.mint();
        assertTrue(!pages.isDrawn(1));
        vm.prank(owner);
        pages.setIsDrawn(1);
        assertTrue(pages.isDrawn(1));
    }

    function testRevertSetIsDrawn() public {
        goop.mint(minter, pages.MINT_COST());
        vm.prank(minter);
        pages.mint();
        vm.expectRevert("UNAUTHORIZED");
        pages.setIsDrawn(1);
    }
}
