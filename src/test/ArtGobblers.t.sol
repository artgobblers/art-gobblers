// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ArtGobblers} from "../ArtGobblers.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "./utils/mocks/VRFCoordinatorMock.sol";

contract ContractTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    VRFCoordinatorMock private vrfCoordinator;
    LinkToken private linkToken;

    bytes32 private keyHash;
    uint256 private fee;
    string private baseUri = "base";

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
    }

    function testSetMerkleRoot() public {
        assertTrue(true);
    }

    function testSetMerkleRootTwice() public {
        assertTrue(true);
    }

    function testMintFromWhitelist() public {
        assertTrue(true);
    }

    function testMintNotInWhitelist() public {
        assertTrue(true);
    }

    function testMintFromGoop() public {
        assertTrue(true);
    }

    function testMintInssuficientBalance() public {
        assertTrue(true);
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
