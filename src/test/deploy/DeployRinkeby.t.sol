// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {DeployRinkeby} from "../../../script/deploy/DeployRinkeby.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {ArtGobblers} from "../../ArtGobblers.sol";
import {Pages} from "../../Pages.sol";

contract DeployRinkebyTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    DeployRinkeby deployScript;

    function setUp() public {
        deployScript = new DeployRinkeby();
        deployScript.run();
    }

    // test page addresses where correctly set
    function testPagesAddressCorrectness() public {
        assertEq(address(deployScript.artGobblers()), deployScript.pages().artGobblers());
        assertEq(address(deployScript.goo()), address(deployScript.pages().goo()));
    }

    // test that merkle root was correctly set
    function testMerkleRoot() public {
        vm.warp(deployScript.mintStart());
        //use merkle root as user to test simple proof
        address user = deployScript.root();
        bytes32[] memory proof;
        ArtGobblers gobblers = deployScript.artGobblers();
        vm.prank(user);
        gobblers.claimGobbler(proof);
        // verify gobbler ownership
        assertEq(gobblers.ownerOf(1), user);
    }

    // test cold wallet was appropriately set
    function testColdWallet() public {
        address coldWallet = deployScript.coldWallet();
        address communityOwner = deployScript.teamReserve().owner();
        address teamOwner = deployScript.communityReserve().owner();
        assertEq(coldWallet, communityOwner);
        assertEq(coldWallet, teamOwner);
    }

    // test URIs are correctly set
    function testURIs() public {
        ArtGobblers gobblers = deployScript.artGobblers();
        assertEq(gobblers.BASE_URI(), deployScript.gobblerBaseUri());
        assertEq(gobblers.UNREVEALED_URI(), deployScript.gobblerUnrevealedUri());
        Pages pages = deployScript.pages();
        assertEq(pages.BASE_URI(), deployScript.pagesBaseUri());
    }
}
