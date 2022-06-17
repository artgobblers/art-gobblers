// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {Goo} from "../Goo.sol";

contract GoopTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;
    address payable[] internal users;
    Goo internal goop;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        goop = new Goo(address(this), users[0]);
    }

    function testMintByAuthority() public {
        uint256 initialSupply = goop.totalSupply();
        uint256 mintAmount = 100000;
        goop.mintForGobblers(address(this), mintAmount);
        uint256 finalSupply = goop.totalSupply();
        assertEq(finalSupply, initialSupply + mintAmount);
    }

    function testMintByNonAuthority() public {
        uint256 mintAmount = 100000;
        vm.prank(users[0]);
        vm.expectRevert(Goo.Unauthorized.selector);
        goop.mintForGobblers(address(this), mintAmount);
    }

    function testSetPages() public {
        goop.mintForGobblers(address(this), 1000000);
        uint256 initialSupply = goop.totalSupply();
        uint256 burnAmount = 100000;
        vm.prank(users[0]);
        goop.burnForPages(address(this), burnAmount);
        uint256 finalSupply = goop.totalSupply();
        assertEq(finalSupply, initialSupply - burnAmount);
    }

    function testBurnAllowed() public {
        uint256 mintAmount = 100000;
        goop.mintForGobblers(address(this), mintAmount);
        uint256 burnAmount = 30000;
        goop.burnForGobblers(address(this), burnAmount);
        uint256 finalBalance = goop.balanceOf(address(this));
        assertEq(finalBalance, mintAmount - burnAmount);
    }

    function testBurnNotAllowed() public {
        uint256 mintAmount = 100000;
        goop.mintForGobblers(address(this), mintAmount);
        uint256 burnAmount = 200000;
        vm.expectRevert(stdError.arithmeticError);
        goop.burnForGobblers(address(this), burnAmount);
    }
}
