// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {Goo} from "../src/Goo.sol";

contract GooTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;
    address payable[] internal users;
    Goo internal goo;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        goo = new Goo(address(this), users[0]);
    }

    function testMintByAuthority() public {
        uint256 initialSupply = goo.totalSupply();
        uint256 mintAmount = 100000;
        goo.mintForGobblers(address(this), mintAmount);
        uint256 finalSupply = goo.totalSupply();
        assertEq(finalSupply, initialSupply + mintAmount);
    }

    function testMintByNonAuthority() public {
        uint256 mintAmount = 100000;
        vm.prank(users[0]);
        vm.expectRevert(Goo.Unauthorized.selector);
        goo.mintForGobblers(address(this), mintAmount);
    }

    function testSetPages() public {
        goo.mintForGobblers(address(this), 1000000);
        uint256 initialSupply = goo.totalSupply();
        uint256 burnAmount = 100000;
        vm.prank(users[0]);
        goo.burnForPages(address(this), burnAmount);
        uint256 finalSupply = goo.totalSupply();
        assertEq(finalSupply, initialSupply - burnAmount);
    }

    function testBurnAllowed() public {
        uint256 mintAmount = 100000;
        goo.mintForGobblers(address(this), mintAmount);
        uint256 burnAmount = 30000;
        goo.burnForGobblers(address(this), burnAmount);
        uint256 finalBalance = goo.balanceOf(address(this));
        assertEq(finalBalance, mintAmount - burnAmount);
    }

    function testBurnNotAllowed() public {
        uint256 mintAmount = 100000;
        goo.mintForGobblers(address(this), mintAmount);
        uint256 burnAmount = 200000;
        vm.expectRevert(stdError.arithmeticError);
        goo.burnForGobblers(address(this), burnAmount);
    }
}
