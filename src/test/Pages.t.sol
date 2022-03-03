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
    address internal mintAuth;
    address internal drawAuth;
    address internal user;
    Goop internal goop;
    Pages internal pages;

    //encodings for expectRevert
    bytes insufficientBalance =
        abi.encodeWithSignature("InsufficientBalance()");
    bytes unauthorized = abi.encodeWithSignature("Unauthorized()");

    function setUp() public {
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

    function testRegularMint() public {
        goop.mint(user, pages.mintCost());
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

    //TODO: fix test once pricing parameters are in
    // function testInsufficientBalance() public {
    // }

    function testSetIsDrawn() public {
        goop.mint(user, pages.mintCost());
        vm.prank(user);
        pages.mint();
        assertTrue(!pages.isDrawn(1));
        vm.prank(drawAuth);
        pages.setIsDrawn(1);
        assertTrue(pages.isDrawn(1));
    }

    function testRevertSetIsDrawn() public {
        goop.mint(user, pages.mintCost());
        vm.prank(user);
        pages.mint();
        vm.expectRevert(unauthorized);
        pages.setIsDrawn(1);
    }
}
