// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {ArtGobblers} from "../ArtGobblers.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "./utils/mocks/VRFCoordinatorMock.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract ArtGobblersTest is DSTestPlus {
    using Strings for uint256;

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

    uint256[] ids;

    //encodings for expectRevert
    bytes unauthorized = abi.encodeWithSignature("Unauthorized()");
    bytes insufficientLinkBalance = abi.encodeWithSignature("InsufficientLinkBalance()");
    bytes insufficientGobblerBalance = abi.encodeWithSignature("InsufficientGobblerBalance()");
    bytes noRemainingLegendary = abi.encodeWithSignature("NoRemainingLegendaryGobblers()");

    bytes insufficientBalance = abi.encodeWithSignature("InsufficientBalance()");
    bytes noRemainingGobblers = abi.encodeWithSignature("NoRemainingGobblers()");

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        gobblers = new ArtGobblers(address(vrfCoordinator), address(linkToken), keyHash, fee, baseUri);
        goop = gobblers.goop();
        pages = gobblers.pages();
    }

    function testSetMerkleRoot() public {
        bytes32 root = "root";
        assertTrue(root != gobblers.merkleRoot());
        gobblers.setMerkleRoot(root);
        assertEq(root, gobblers.merkleRoot());
        assertTrue(true);
    }

    function testSetMerkleRootTwice() public {
        gobblers.setMerkleRoot("root1");
        vm.expectRevert(unauthorized);
        gobblers.setMerkleRoot("root2");
    }

    function testMintFromWhitelist() public {
        address user = users[0];
        gobblers.setMerkleRoot(keccak256(abi.encodePacked(user)));
        bytes32[] memory proof;
        vm.prank(user);
        gobblers.mintFromWhitelist(proof);
        // verify gobbler ownership
        assertEq(gobblers.ownerOf(1), user);
        // and page ownership as well
        assertEq(pages.ownerOf(1), user);
    }

    function testMintNotInWhitelist() public {
        bytes32[] memory proof;
        vm.expectRevert(unauthorized);
        gobblers.mintFromWhitelist(proof);
    }

    function testMintFromGoop() public {
        gobblers.setMerkleRoot("root");
        uint256 cost = gobblers.gobblerPrice();
        vm.prank(address(gobblers));
        goop.mint(users[0], cost);
        vm.prank(users[0]);
        gobblers.mintFromGoop();
        assertEq(gobblers.ownerOf(1), users[0]);
    }

    function testMintInsufficientBalance() public {
        gobblers.setMerkleRoot("root");
        vm.prank(users[0]);
        vm.expectRevert(stdError.arithmeticError);
        gobblers.mintFromGoop();
    }

    // //@notice Long running test, commented out to ease development
    // function testMintMaxFromGoop() public {
    //     //total supply - legendary gobblers - whitelist gobblers
    //     uint256 maxMintableWithGoop = gobblers.MAX_SUPPLY() - 10 - 2000;
    //     mintGobblerToAddress(users[0], maxMintableWithGoop);
    //     vm.expectRevert(noRemainingGobblers);
    //     vm.prank(users[0]);
    //     gobblers.mintFromGoop();
    // }

    function testInitialGobblerPrice() public {
        uint256 cost = gobblers.gobblerPrice();
        uint256 maxDelta = 10; // 0.00000000000000001

        assertApproxEq(cost, uint256(gobblers.initialPrice()), maxDelta);
    }

    function testLegendaryGobblerMintBeforeStart() public {
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(users[0]);
        gobblers.mintLegendaryGobbler(ids);
    }

    function testLegendaryGobblerInitialPrice() public {
        // start of initial auction
        vm.warp(block.timestamp + 30 days);
        uint256 cost = gobblers.legendaryGobblerPrice();
        // initial auction should start at a cost of 100
        assertEq(cost, 100);
    }

    function testLegendaryGobblerFinalPrice() public {
        //30 days for initial auction start, 40 days after initial auction
        vm.warp(block.timestamp + 70 days);
        uint256 cost = gobblers.legendaryGobblerPrice();
        // auction price should be 0 after more than 30 days have passed
        assertEq(cost, 0);
    }

    function testLegendaryGobblerMidPrice() public {
        //30 days for initial auction start, 15 days after initial auction
        vm.warp(block.timestamp + 45 days);
        uint256 cost = gobblers.legendaryGobblerPrice();
        // auction price should be 50 mid way through auction
        assertEq(cost, 50);
    }

    function testLegendaryGobblerMinStartPrice() public {
        //30 days for initial auction start, 15 days after initial auction
        vm.warp(block.timestamp + 60 days);
        vm.prank(users[0]);
        //empty id list
        uint256[] memory _ids;
        gobblers.mintLegendaryGobbler(_ids);
        uint256 startCost = gobblers.legendaryGobblerPrice();
        // next gobbler should start at a price of 100
        assertEq(startCost, 100);
    }

    function testMintLegendaryGobbler() public {
        uint256 startTime = block.timestamp + 30 days;
        vm.warp(startTime);

        uint256 cost = gobblers.legendaryGobblerPrice();
        mintGobblerToAddress(users[0], cost);
        //assert cost is not zero
        assertTrue(cost != 0);
        for (uint256 i = 1; i <= cost; i++) {
            //all gobblers owned by user
            ids.push(i);
            assertEq(gobblers.ownerOf(i), users[0]);
        }
        vm.warp(startTime);
        vm.prank(users[0]);
        gobblers.mintLegendaryGobbler(ids);
        //legendary is owned by user
        assertEq(gobblers.ownerOf(gobblers.currentLegendaryId()), users[0]);
        for (uint256 i = 1; i <= cost; i++) {
            //all gobblers burned
            ids.push(i);

            // TODO: will need to change this when we switch to 1155B
            vm.expectRevert("NOT_MINTED");
            gobblers.ownerOf(i);
        }
    }

    function testUnmintedUri() public {
        assertEq(gobblers.tokenURI(1), "");
    }

    function testUnrevealedUri() public {
        gobblers.setMerkleRoot(0);
        uint256 gobblerCost = gobblers.gobblerPrice();
        vm.prank(address(gobblers));
        goop.mint(users[0], gobblerCost);
        vm.prank(users[0]);
        gobblers.mintFromGoop();
        // assert gobbler not revealed after mint
        assertTrue(stringEquals(gobblers.tokenURI(1), gobblers.UNREVEALED_URI()));
    }

    function testRevealedUri() public {
        mintGobblerToAddress(users[0], 1);

        // unrevealed gobblers have 0 value attributes
        assertEq(gobblers.getStakingMultiple(1), 0);
        setRandomnessAndReveal(1, "seed");
        (uint256 expectedIndex, , ) = gobblers.attributeList(1);
        string memory expectedURI = string(abi.encodePacked(gobblers.BASE_URI(), expectedIndex.toString()));
        assertTrue(stringEquals(gobblers.tokenURI(1), expectedURI));
    }

    function testMintedLegendaryURI() public {
        //mint legendary
        vm.warp(block.timestamp + 70 days);
        uint256[] memory _ids;
        gobblers.mintLegendaryGobbler(_ids);
        uint256 legendaryId = gobblers.currentLegendaryId();
        //expected URI should not be shuffled
        string memory expectedURI = string(abi.encodePacked(gobblers.BASE_URI(), legendaryId.toString()));
        string memory actualURI = gobblers.tokenURI(legendaryId);
        assertTrue(stringEquals(actualURI, expectedURI));
    }

    function testUnmintedLegendaryUri() public {
        uint256 legendaryId = gobblers.currentLegendaryId() + 1;
        assertEq(gobblers.tokenURI(legendaryId), "");
    }

    function testCantSetRandomSeedWithoutRevealing() public {
        mintGobblerToAddress(users[0], 2);
        setRandomnessAndReveal(1, "seed");
        // should fail since there is one remaining gobbler to be revealed with seed
        vm.expectRevert(unauthorized);
        setRandomnessAndReveal(1, "seed");
    }

    function testMultiReveal() public {
        mintGobblerToAddress(users[0], 100);
        // first 100 gobblers should be unrevealed
        for (uint256 i = 1; i <= 100; i++) {
            assertEq(gobblers.tokenURI(i), gobblers.UNREVEALED_URI());
        }
        setRandomnessAndReveal(50, "seed");
        // first 50 gobblers should now be revealed
        for (uint256 i = 1; i <= 50; i++) {
            assertTrue(!stringEquals(gobblers.tokenURI(i), gobblers.UNREVEALED_URI()));
        }
        // and next 50 should remain unrevealed
        for (uint256 i = 51; i <= 100; i++) {
            assertTrue(stringEquals(gobblers.tokenURI(i), gobblers.UNREVEALED_URI()));
        }
    }

    // //@notice Long running test, commented out to ease development
    // // test whether all ids are assigned after full reveal
    // function testAllIdsUnique() public {
    //     int256[10001] memory counts;
    //     // mint all
    //     uint256 mintCount = gobblers.MAX_GOOP_MINT();

    //     mintGobblerToAddress(users[0], mintCount);
    //     setRandomnessAndReveal(mintCount, "seed");
    //     // count ids
    //     for (uint256 i = 1; i < 10001; i++) {
    //         (uint256 tokenId, , ) = gobblers.attributeList(i);
    //         counts[tokenId]++;
    //     }
    //     // check that all ids are unique
    //     for (uint256 i = 1; i < 10001; i++) {
    //         assertTrue(counts[i] <= 1);
    //     }
    // }

    function testFeedArt() public {
        assertTrue(true);
    }

    function testSimpleRewards() public {
        mintGobblerToAddress(users[0], 1);
        // balance should initially be zero
        assertEq(gobblers.goopBalance(1), 0);
        vm.warp(block.timestamp + 100000);
        // balance should be zero while no reveal
        assertEq(gobblers.goopBalance(1), 0);
        setRandomnessAndReveal(1, "seed");
        // balance should grow on same timestamp after reveal
        assertTrue(gobblers.goopBalance(1) != 0);
    }

    function testGoopRemoval() public {
        mintGobblerToAddress(users[0], 1);
        vm.warp(block.timestamp + 100000);
        setRandomnessAndReveal(1, "seed");
        // balance should grow on same timestamp after reveal
        uint256 initialBalance = gobblers.goopBalance(1);
        //10%
        uint256 removalAmount = initialBalance / 10;
        vm.prank(users[0]);
        gobblers.removeGoop(1, removalAmount);
        uint256 finalBalance = gobblers.goopBalance(1);
        // balance should change
        assertTrue(initialBalance != finalBalance);
        assertEq(initialBalance, finalBalance + removalAmount);
        // user should have removed goop
        assertEq(goop.balanceOf(users[0]), removalAmount);
    }

    function testCantRemoveGoop() public {
        mintGobblerToAddress(users[0], 1);
        vm.warp(block.timestamp + 100000);
        setRandomnessAndReveal(1, "seed");
        vm.prank(users[1]);
        vm.expectRevert(unauthorized);
        gobblers.removeGoop(1, 1);
    }

    function testGoopAddition() public {
        mintGobblerToAddress(users[0], 1);
        vm.warp(block.timestamp + 100000);
        setRandomnessAndReveal(1, "seed");
        // balance should grow on same timestamp after reveal
        uint256 initialBalance = gobblers.goopBalance(1);
        vm.prank(address(gobblers));
        uint256 additionAmount = 1000;
        goop.mint(users[0], additionAmount);
        vm.prank(users[0]);
        gobblers.addGoop(1, additionAmount);
        uint256 finalBalance = gobblers.goopBalance(1);
        // balance should change
        assertTrue(initialBalance != finalBalance);
        assertEq(initialBalance + additionAmount, finalBalance);
    }

    // convenience function to mint single gobbler from goop
    function mintGobblerToAddress(address addr, uint256 num) internal {
        // merkle root must be set before mints are allowed
        if (gobblers.merkleRoot() == 0) {
            gobblers.setMerkleRoot("root");
        }

        uint256 timeDelta = 10 hours;

        for (uint256 i = 0; i < num; i++) {
            vm.warp(block.timestamp + timeDelta);
            vm.startPrank(address(gobblers));
            goop.mint(addr, gobblers.gobblerPrice());
            vm.stopPrank();
            vm.prank(addr);
            gobblers.mintFromGoop();
        }
        vm.stopPrank();
    }

    // convenience function to call back vrf with randomness and reveal gobblers
    function setRandomnessAndReveal(uint256 numReveal, string memory seed) internal {
        bytes32 requestId = gobblers.getRandomSeed();
        uint256 randomness = uint256(keccak256(abi.encodePacked(seed)));
        // call back from coordinator
        vrfCoordinator.callBackWithRandomness(requestId, randomness, address(gobblers));
        gobblers.revealGobblers(numReveal);
    }

    // string equality based on hash
    function stringEquals(string memory s1, string memory s2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}
