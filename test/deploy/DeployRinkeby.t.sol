// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {DeployRinkeby} from "../../script/deploy/DeployRinkeby.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {Pages} from "../../src/Pages.sol";
import {ArtGobblers} from "../../src/ArtGobblers.sol";

contract DeployRinkebyTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    DeployRinkeby deployScript;

    function setUp() public {
        deployScript = new DeployRinkeby();
        deployScript.run();
    }

    /// @notice Test goo addresses where correctly set.
    function testGooAddressCorrectness() public {
        assertEq(deployScript.goo().artGobblers(), address(deployScript.artGobblers()));
        assertEq(address(deployScript.goo().pages()), address(deployScript.pages()));
    }

    /// @notice Test page addresses where correctly set.
    function testPagesAddressCorrectness() public {
        assertEq(address(deployScript.pages().artGobblers()), address(deployScript.artGobblers()));
        assertEq(address(deployScript.pages().goo()), address(deployScript.goo()));
    }

    /// @notice Test that merkle root was correctly set.
    function testMerkleRoot() public {
        vm.warp(deployScript.mintStart());
        // Use merkle root as user to test simple proof.
        address user = deployScript.root();
        bytes32[] memory proof;
        ArtGobblers gobblers = deployScript.artGobblers();
        vm.prank(user);
        gobblers.claimGobbler(proof);
        // Verify gobbler ownership.
        assertEq(gobblers.ownerOf(1), user);
    }

    /// @notice Test cold wallet was appropriately set.
    function testColdWallet() public {
        address coldWallet = deployScript.coldWallet();
        address communityOwner = deployScript.teamReserve().owner();
        address teamOwner = deployScript.communityReserve().owner();
        assertEq(coldWallet, communityOwner);
        assertEq(coldWallet, teamOwner);
    }

    /// @notice Test URIs are correctly set.
    function testURIs() public {
        ArtGobblers gobblers = deployScript.artGobblers();
        assertEq(gobblers.BASE_URI(), deployScript.gobblerBaseUri());
        assertEq(gobblers.UNREVEALED_URI(), deployScript.gobblerUnrevealedUri());
        Pages pages = deployScript.pages();
        assertEq(pages.BASE_URI(), deployScript.pagesBaseUri());
    }
}
