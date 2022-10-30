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
        vm.setEnv("GOO_PRIVATE_KEY", "0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd");

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

    /// @notice Test that gobblers ownership is correctly transferred to governor.
    function testGobblerOwnership() public {
        assertEq(deployScript.artGobblers().owner(), deployScript.governorWallet());
    }

    /// @notice Test that merkle root is set correctly.
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

    function testGobblerClaim() public {
        ArtGobblers gobblers = deployScript.artGobblers();

        // Address is in the merkle root.
        address minter = 0x0fb90B14e4BF3a2e5182B9b3cBD03e8d33b5b863;

        // Merkle proof.
        bytes32[] memory proof = new bytes32[](11);
        proof[0] = 0x541a56539b694a70dde9dabe952bb520f496fce67614316102d0a842d3615f2a;
        proof[1] = 0x48b4e269c7ce862127a0acc74a4ea667571fc3d7794d3c738ba5012ab356e1bd;
        proof[2] = 0x44ede3b0062acbd441c2862a9dbfbef56939941b10f3dfd5681e352e433a40ba;
        proof[3] = 0xbbbdd1b0ab9aade132a0d46f55f9a6b9aa4cc36e40eaca0c0edde920dfd10352;
        proof[4] = 0x40696f4fa548ba37ba76376a7e1d537794ef7c76beedb45bf2e67d83b91fb35d;
        proof[5] = 0x10ecbfee943986149ef31225bd2da45c2f0d1c7aaebb6c9fb66a938e90d57995;
        proof[6] = 0x8ed4b1f65bacc0c3374030b948d54004b636896390fa8ade8e81dec61b382231;
        proof[7] = 0xcd29788189153cafa66cb771589e5211d6c0418de49b25685b5d678ed136ad1d;
        proof[8] = 0xeffb064155d13bc87b27f9f78d811053863836c89e49c6f96f3856b0144370ee;
        proof[9] = 0x7413ded58393d42ce39eaedd07d8b57f62e5c068d5608300cc7cccd96ca40380;
        proof[10] = 0xf3927c3b5a5dcce415463d504510cc3a3da57a48199a96f49e0257e2cd66d3a5;

        // Initial balance should be zero.
        assertEq(gobblers.balanceOf(minter), 0);

        // Move time and mint.
        vm.warp(gobblers.mintStart());
        vm.prank(minter);
        gobblers.claimGobbler(proof);

        // Check that balance has increased.
        assertEq(gobblers.balanceOf(minter), 1);
    }
}
