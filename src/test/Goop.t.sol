// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/stdlib.sol";
import {Goop} from "../Goop.sol";

contract GoopTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;
    address payable[] internal users;
    Goop internal goop;

    //encodings for expectRevert
    bytes unauthorized = abi.encodeWithSignature("Unauthorized()");

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        goop = new Goop(address(this));
    }

    function testMintByAuthority() public {
        uint256 initialSupply = goop.totalSupply();
        uint256 mintAmount = 100000;
        goop.mint(address(this), mintAmount);
        uint256 finalSupply = goop.totalSupply();
        assertEq(finalSupply, initialSupply + mintAmount);
    }

    function testMintByNonAuthority() public {
        uint256 initialSupply = goop.totalSupply();
        uint256 mintAmount = 100000;
        vm.prank(users[0]);
        vm.expectRevert(unauthorized);
        goop.mint(address(this), mintAmount);
    }

    function testSetPages() public {
        uint256 initialSupply = goop.totalSupply();
        uint256 mintAmount = 100000;
        goop.setPages(users[0]);
        vm.prank(users[0]);
        goop.mint(address(this), mintAmount);
        uint256 finalSupply = goop.totalSupply();
        assertEq(finalSupply, initialSupply + mintAmount);
    }

    function testBurnAllowed() public {
        uint256 mintAmount = 100000;
        goop.mint(address(this), mintAmount);
        uint256 burnAmount = 30000;
        goop.burn(address(this), burnAmount);
        uint256 finalBalance = goop.balanceOf(address(this));
        assertEq(finalBalance, mintAmount - burnAmount);
    }

    function testBurnNotAllowed() public {
        uint256 mintAmount = 100000;
        goop.mint(address(this), mintAmount);
        uint256 burnAmount = 200000;
        vm.expectRevert(stdError.arithmeticError);
        goop.burn(address(this), burnAmount);
    }
}
