// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/stdlib.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";

contract PagesTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;
    address payable[] internal users;
    address internal mintAuth;
    address internal drawAuth;
    address internal user;
    Goop internal goop;
    Pages internal pages;
    uint256 mintStart;

    //encodings for expectRevert
    bytes unauthorized = abi.encodeWithSignature("Unauthorized()");
    bytes mintNotStarted = abi.encodeWithSignature("MintNotStarted()");

    function setUp() public {
        //avoid starting at timestamp = 0 for ease of testing
        vm.warp(block.timestamp + 1);
        utils = new Utilities();
        users = utils.createUsers(5);
        drawAuth = users[0];
        goop = new Goop(address(this));
        pages = new Pages(address(goop), drawAuth);
        //deploying contract is mint authority
        mintAuth = address(this);
        goop.setPages(address(pages));
        user = users[1];
    }

    function testMintBeforeSetMint() public {
        vm.expectRevert(mintNotStarted);
        vm.prank(user);
        pages.mint();
    }

    function testMintBeforeStart() public {
        //set mint start in future
        pages.setMintStart(block.timestamp + 1);
        vm.expectRevert(mintNotStarted);
        vm.prank(user);
        pages.mint();
    }

    function testRegularMint() public {
        pages.setMintStart(block.timestamp);
        goop.mint(user, pages.pagePrice());
        vm.prank(user);
        pages.mint();
        assertEq(user, pages.ownerOf(1));
    }

    function testMintByAuthority() public {
        //mint by authority for user
        pages.mintByAuth(user);
        assertEq(user, pages.ownerOf(1));
    }

    function testMintByAuthorityRevert() public {
        vm.prank(user);
        vm.expectRevert(unauthorized);
        pages.mintByAuth(user);
    }

    function testInitialPrice() public {
        pages.setMintStart(block.timestamp);
        uint256 cost = pages.pagePrice();
        uint256 expectedCost = 419999999999999967660; // computed offline
        assertEq(cost, expectedCost);
    }

    function testInsufficientBalance() public {
        pages.setMintStart(block.timestamp);
        vm.prank(user);
        vm.expectRevert(stdError.arithmeticError);
        pages.mint();
    }

    function testSetIsDrawn() public {
        pages.setMintStart(block.timestamp);
        goop.mint(user, pages.pagePrice());
        vm.prank(user);
        pages.mint();
        assertTrue(!pages.isDrawn(1));
        vm.prank(drawAuth);
        pages.setIsDrawn(1);
        assertTrue(pages.isDrawn(1));
    }

    function testRevertSetIsDrawn() public {
        pages.setMintStart(block.timestamp);
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
