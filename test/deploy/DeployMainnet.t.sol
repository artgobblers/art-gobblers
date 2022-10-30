// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {DeployMainnet} from "../../script/deploy/DeployMainnet.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {Pages} from "../../src/Pages.sol";
import {ArtGobblers} from "../../src/ArtGobblers.sol";

contract DeployMainnetTest is DSTestPlus {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    DeployMainnet deployScript;

    function setUp() public {
        
        vm.setEnv("DEPLOYER_PRIVATE_KEY", "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        vm.setEnv("GOBBLER_PRIVATE_KEY", "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
        vm.setEnv("PAGES_PRIVATE_KEY", "0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc");
        vm.setEnv("GOO_PRIVATE_KEY", "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd");

        vm.deal(vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY")), type(uint64).max);

        deployScript = new DeployMainnet();
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
    function testGobblerOwnership() public {
        assertEq(deployScript.artGobblers().owner(), deployScript.governorWallet());
    }

    function testRoot() public {
        assertEq(deployScript.root(), deployScript.artGobblers().merkleRoot());
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
