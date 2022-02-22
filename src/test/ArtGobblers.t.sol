// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ArtGobblers} from "../ArtGobblers.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "./utils/mocks/VRFCoordinatorMock.sol";

contract ContractTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    VRFCoordinatorMock private vrfCoordinator;
    LinkToken private linkToken;
    Goop goop;
    Pages pages;

    bytes32 private keyHash;
    uint256 private fee;
    string private baseUri = "base";

    //encodings for expectRevert
    bytes unauthorized = abi.encodeWithSignature("Unauthorized()");
    bytes insufficientLinkBalance =
        abi.encodeWithSignature("InsufficientLinkBalance()");
    bytes insufficientGobblerBalance =
        abi.encodeWithSignature("InsufficientGobblerBalance()");
    bytes noRemainingLegendary =
        abi.encodeWithSignature("NoRemainingLegendaryGobblers()");

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        gobblers = new ArtGobblers(
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            baseUri
        );
        goop = gobblers.goop();
        pages = gobblers.pages();
    }

    function testSetMerkleRoot() public {
        bytes32 root = keccak256(abi.encodePacked("root"));
        assertTrue(root != gobblers.merkleRoot());
        gobblers.setMerkleRoot(root);
        assertEq(root, gobblers.merkleRoot());
        assertTrue(true);
    }

    function testSetMerkleRootTwice() public {
        bytes32 root = keccak256(abi.encodePacked("root"));
        gobblers.setMerkleRoot(root);
        root = keccak256(abi.encodePacked(root));
        vm.expectRevert(unauthorized);
        gobblers.setMerkleRoot(root);
    }

    function testMintFromWhitelist() public {
        // address left = address(0xBEEF);
        // address right = address(0xDEAD);
        // bytes32 root = keccak256(abi.encodePacked(left, right));
        // gobblers.setMerkleRoot(root);
        // bytes32[] memory proof;
        assertTrue(true);
    }

    function testMintNotInWhitelist() public {
        bytes32 root = keccak256(abi.encodePacked("root"));
        assertTrue(root != gobblers.merkleRoot());
        bytes32[] memory proof;
        vm.expectRevert(unauthorized);
        gobblers.mintFromWhitelist(proof);
    }

    function testMintFromGoop() public {
        vm.warp(gobblers.goopMintStart());
        vm.prank(address(gobblers));
        goop.mint(users[0], 1);
        vm.prank(users[0]);
        gobblers.mintFromGoop();
        assertEq(gobblers.ownerOf(1), users[0]);
    }

    function testMintInssuficientBalance() public {
        vm.warp(gobblers.goopMintStart());
        vm.prank(users[0]);
        gobblers.mintFromGoop();
        assertEq(gobblers.ownerOf(1), users[0]);
    }

    function testMintBeforeStart() public {
        vm.prank(address(gobblers));
        goop.mint(users[0], 1);
        vm.expectRevert(unauthorized);
        vm.prank(users[0]);
        gobblers.mintFromGoop();
    }

    function testLegendaryGobblerMintBeforeStart() public {
        assertTrue(true);
    }

    function testmintLegendaryGobbler() public {
        assertTrue(true);
    }

    function testStartOfNewLegendaryAuction() public {
        assertTrue(true);
    }

    function testTokenUriNotMinted() public {
        assertTrue(true);
    }

    function testTokenUriMinted() public {
        assertTrue(true);
    }

    function testFeedArt() public {
        assertTrue(true);
    }

    function testSimpleStaking() public {
        assertTrue(true);
    }

    function testClaimRewards() public {
        assertTrue(true);
    }

    function testUnstakeGoop() public {
        assertTrue(true);
    }
}
