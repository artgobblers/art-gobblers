// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {ArtGobblers} from "../ArtGobblers.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "./utils/mocks/VRFCoordinatorMock.sol";
import {MockERC1155} from "solmate/test/utils/mocks/MockERC1155.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract ArtGobblersTest is DSTestPlus, ERC1155TokenReceiver {
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
    bytes alreadyEaten = abi.encodeWithSignature("AlreadyEaten()");
    bytes cannotBurnLegendary = abi.encodeWithSignature("CannotBurnLegendary()");
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

        gobblers = new ArtGobblers(
            keccak256(abi.encodePacked(users[0])),
            block.timestamp,
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            baseUri
        );
        goop = gobblers.goop();
        pages = gobblers.pages();
    }

    function testMintFromWhitelist() public {
        address user = users[0];
        bytes32[] memory proof;
        vm.prank(user);
        gobblers.mintFromWhitelist(proof);
        // verify gobbler ownership
        assertEq(gobblers.ownerOf(1), user);
    }

    function testMintNotInWhitelist() public {
        bytes32[] memory proof;
        vm.expectRevert(unauthorized);
        gobblers.mintFromWhitelist(proof);
    }

    function testMintFromGoop() public {
        uint256 cost = gobblers.gobblerPrice();
        vm.prank(address(gobblers));
        goop.mint(users[0], cost);
        vm.prank(users[0]);
        gobblers.mintFromGoop();
        assertEq(gobblers.ownerOf(1), users[0]);
    }

    function testMintInsufficientBalance() public {
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
        assertEq(cost, 100);

        mintGobblerToAddress(users[0], cost);
        setRandomnessAndReveal(cost, "seed");

        uint256 stakingMultipleSum;

        for (uint256 i = 1; i <= cost; i++) {
            ids.push(i);

            assertEq(gobblers.ownerOf(i), users[0]);

            stakingMultipleSum += gobblers.getGobblerStakingMultiple(i);
        }

        assertEq(gobblers.getUserStakingMultiple(users[0]), stakingMultipleSum);

        vm.warp(startTime); // mintGobblerToAddress warps time forward

        vm.prank(users[0]);
        gobblers.mintLegendaryGobbler(ids);

        (, , uint16 currentLegendaryId) = gobblers.legendaryGobblerAuctionData();

        // Legendary is owned by user.
        assertEq(gobblers.ownerOf(currentLegendaryId), users[0]);

        assertEq(gobblers.getUserStakingMultiple(users[0]), stakingMultipleSum * 2);
        assertEq(gobblers.getGobblerStakingMultiple(currentLegendaryId), stakingMultipleSum * 2);

        for (uint256 i = 1; i <= cost; i++) assertEq(gobblers.ownerOf(i), address(0));
    }

    function testCannotMintLegendaryWithLegendary() public {
        vm.warp(block.timestamp + 70 days);
        vm.prank(users[0]);
        gobblers.mintLegendaryGobbler(ids);

        (, , uint16 legendaryId) = gobblers.legendaryGobblerAuctionData();
        assertEq(legendaryId, 9991);

        uint256 startTime = block.timestamp;

        uint256 cost = gobblers.legendaryGobblerPrice();
        assertEq(cost, 66);

        mintGobblerToAddress(users[0], cost);
        setRandomnessAndReveal(cost, "seed");

        for (uint256 i = 1; i <= cost; i++) ids.push(i);

        vm.warp(startTime); // mintGobblerToAddress warps time forward

        ids[0] = legendaryId; // the legendary we minted

        vm.prank(users[0]);
        vm.expectRevert(cannotBurnLegendary);
        gobblers.mintLegendaryGobbler(ids);
    }

    function testUnmintedUri() public {
        assertEq(gobblers.uri(1), "");
    }

    function testUnrevealedUri() public {
        uint256 gobblerCost = gobblers.gobblerPrice();
        vm.prank(address(gobblers));
        goop.mint(users[0], gobblerCost);
        vm.prank(users[0]);
        gobblers.mintFromGoop();
        // assert gobbler not revealed after mint
        assertTrue(stringEquals(gobblers.uri(1), gobblers.UNREVEALED_URI()));
    }

    function testRevealedUri() public {
        mintGobblerToAddress(users[0], 1);

        // unrevealed gobblers have 0 value attributes
        assertEq(gobblers.getGobblerStakingMultiple(1), 0);
        setRandomnessAndReveal(1, "seed");
        (, uint48 expectedIndex, ) = gobblers.getGobblerData(1);
        string memory expectedURI = string(abi.encodePacked(gobblers.BASE_URI(), uint256(expectedIndex).toString()));
        assertTrue(stringEquals(gobblers.uri(1), expectedURI));
    }

    function testMintedLegendaryURI() public {
        //mint legendary
        vm.warp(block.timestamp + 70 days);

        uint256[] memory _ids; // gobbler should be free at this point

        gobblers.mintLegendaryGobbler(_ids);

        (, , uint16 currentLegendaryId) = gobblers.legendaryGobblerAuctionData();

        //expected URI should not be shuffled
        string memory expectedURI = string(
            abi.encodePacked(gobblers.BASE_URI(), uint256(currentLegendaryId).toString())
        );
        string memory actualURI = gobblers.uri(currentLegendaryId);
        assertTrue(stringEquals(actualURI, expectedURI));
    }

    function testUnmintedLegendaryUri() public {
        (, , uint16 currentLegendaryId) = gobblers.legendaryGobblerAuctionData();

        uint256 legendaryId = currentLegendaryId + 1;
        assertEq(gobblers.uri(legendaryId), "");
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
            assertEq(gobblers.uri(i), gobblers.UNREVEALED_URI());
        }
        setRandomnessAndReveal(50, "seed");
        // first 50 gobblers should now be revealed
        for (uint256 i = 1; i <= 50; i++) {
            assertTrue(!stringEquals(gobblers.uri(i), gobblers.UNREVEALED_URI()));
        }
        // and next 50 should remain unrevealed
        for (uint256 i = 51; i <= 100; i++) {
            assertTrue(stringEquals(gobblers.uri(i), gobblers.UNREVEALED_URI()));
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
    //         (uint256 tokenId, ) = gobblers.getGobblerData(i);
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
        assertEq(gobblers.goopBalance(users[0]), 0);

        vm.warp(block.timestamp + 100000);

        // balance should be zero while no reveal
        assertEq(gobblers.goopBalance(users[0]), 0);

        setRandomnessAndReveal(1, "seed");

        // balance should NOT grow on same timestamp after reveal
        assertEq(gobblers.goopBalance(users[0]), 0);

        vm.warp(block.timestamp + 100000);

        // balance should grow after reveal
        assertGt(gobblers.goopBalance(users[0]), 0);
    }

    function testGoopRemoval() public {
        mintGobblerToAddress(users[0], 1);

        setRandomnessAndReveal(1, "seed");

        vm.warp(block.timestamp + 100000);

        uint256 initialBalance = gobblers.goopBalance(users[0]);

        //10%
        uint256 removalAmount = initialBalance / 10;

        vm.prank(users[0]);
        gobblers.removeGoop(removalAmount);

        uint256 finalBalance = gobblers.goopBalance(users[0]);

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
        vm.expectRevert(stdError.arithmeticError);
        gobblers.removeGoop(1);
    }

    function testGoopAddition() public {
        mintGobblerToAddress(users[0], 1);

        assertEq(gobblers.getGobblerStakingMultiple(1), 0);
        assertEq(gobblers.getUserStakingMultiple(users[0]), 0);

        // waiting after mint to reveal shouldn't effect balance
        vm.warp(block.timestamp + 100000);
        assertEq(gobblers.goopBalance(users[0]), 0);

        setRandomnessAndReveal(1, "seed");

        uint256 gobblerMultiple = gobblers.getGobblerStakingMultiple(1);
        assertGt(gobblerMultiple, 0);
        assertEq(gobblers.getUserStakingMultiple(users[0]), gobblerMultiple);

        vm.prank(address(gobblers));

        uint256 additionAmount = 1000;

        goop.mint(users[0], additionAmount);

        vm.prank(users[0]);

        gobblers.addGoop(additionAmount);

        assertEq(gobblers.goopBalance(users[0]), additionAmount);
    }

    function testStakingMultiplierUpdatesAfterTransfer() public {
        mintGobblerToAddress(users[0], 1);
        setRandomnessAndReveal(1, "seed");

        uint256 initialUserMultiple = gobblers.getUserStakingMultiple(users[0]);
        assertGt(initialUserMultiple, 0);
        assertEq(gobblers.getUserStakingMultiple(users[1]), 0);

        vm.prank(users[0]);
        gobblers.safeTransferFrom(users[0], users[1], 1, 1, "");

        assertEq(gobblers.getUserStakingMultiple(users[0]), 0);
        assertEq(gobblers.getUserStakingMultiple(users[1]), initialUserMultiple);
    }

    function testFeedingArt() public {
        address user = users[0];

        mintGobblerToAddress(user, 1);

        uint256 pagePrice = pages.pagePrice();

        vm.prank(address(gobblers));
        goop.mint(user, pagePrice);

        vm.startPrank(user);

        pages.mint();

        pages.setApprovalForAll(address(gobblers), true);

        gobblers.feedArt(1, address(pages), 1);

        vm.stopPrank();

        assertEq(gobblers.getGobblerFromFedArt(address(pages), 1), 1);
    }

    function testCantFeedArtToUnownedGobbler() public {
        address user = users[0];

        uint256 pagePrice = pages.pagePrice();

        vm.prank(address(gobblers));
        goop.mint(user, pagePrice);

        vm.startPrank(user);

        pages.mint();

        pages.setApprovalForAll(address(gobblers), true);

        vm.expectRevert(unauthorized);
        gobblers.feedArt(1, address(pages), 1);

        vm.stopPrank();
    }

    function testCantFeedUnownedArt() public {
        address user = users[0];

        mintGobblerToAddress(user, 1);

        vm.startPrank(user);

        pages.setApprovalForAll(address(gobblers), true);

        vm.expectRevert("WRONG_FROM");
        gobblers.feedArt(1, address(pages), 1);

        vm.stopPrank();
    }

    function testCantFeedArtTwice() public {
        MockERC1155 token = new MockERC1155();

        address user = users[0];

        mintGobblerToAddress(user, 1);

        token.mint(user, 1, 2, "");

        vm.startPrank(user);

        token.setApprovalForAll(address(gobblers), true);

        gobblers.feedArt(1, address(token), 1);

        vm.expectRevert(alreadyEaten);
        gobblers.feedArt(1, address(token), 1);

        vm.stopPrank();
    }

    // convenience function to mint single gobbler from goop
    function mintGobblerToAddress(address addr, uint256 num) internal {
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
