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
import {ERC1155BLockupVault} from "../utils/ERC1155BLockupVault.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "./utils/mocks/VRFCoordinatorMock.sol";
import {MockERC1155} from "solmate/test/utils/mocks/MockERC1155.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

/// @notice Unit test for Art Gobbler Contract.
contract ArtGobblersTest is DSTestPlus, ERC1155TokenReceiver {
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers internal gobblers;
    VRFCoordinatorMock internal vrfCoordinator;
    LinkToken internal linkToken;
    Goop internal goop;
    Pages internal pages;
    ERC1155BLockupVault internal team;

    bytes32 private keyHash;
    uint256 private fee;
    string private baseUri = "base";

    uint256[] ids;

    /*//////////////////////////////////////////////////////////////
                                  SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));

        team = new ERC1155BLockupVault(address(this), 730 days);

        goop = new Goop(
            // Gobblers:
            utils.predictContractAddress(address(this), 1),
            // Pages:
            utils.predictContractAddress(address(this), 2)
        );

        gobblers = new ArtGobblers(
            keccak256(abi.encodePacked(users[0])),
            block.timestamp,
            goop,
            address(team),
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            baseUri
        );

        pages = new Pages(block.timestamp, address(gobblers), goop);
    }

    /*//////////////////////////////////////////////////////////////
                               MINT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that you can mint from mintlist successfully.
    function testMintFromMintlist() public {
        address user = users[0];
        bytes32[] memory proof;
        vm.prank(user);
        gobblers.mintFromMintlist(proof);
        // verify gobbler ownership
        assertEq(gobblers.ownerOf(1), user);
    }

    /// @notice Test that an invalid mintlist proof reverts.
    function testMintNotInMintlist() public {
        bytes32[] memory proof;
        vm.expectRevert(ArtGobblers.Unauthorized.selector);
        gobblers.mintFromMintlist(proof);
    }

    /// @notice Test that you can successfully mint from goop.
    function testMintFromGoop() public {
        uint256 cost = gobblers.gobblerPrice();
        vm.prank(address(gobblers));
        goop.mintForGobblers(users[0], cost);
        vm.prank(users[0]);
        gobblers.mintFromGoop();
        assertEq(gobblers.ownerOf(1), users[0]);
    }

    /// @notice Test that trying to mint with insufficient balance reverts.
    function testMintInsufficientBalance() public {
        vm.prank(users[0]);
        vm.expectRevert(stdError.arithmeticError);
        gobblers.mintFromGoop();
    }

    /// @notice Test that initial gobbler price is what we expect.
    function testInitialGobblerPrice() public {
        uint256 cost = gobblers.gobblerPrice();
        uint256 maxDelta = 10; // 0.00000000000000001
        assertApproxEq(cost, uint256(gobblers.initialPrice()), maxDelta);
    }

    /// @notice Test that 10th gobbler is minted for vault
    function testMintForVault() public {
        mintGobblerToAddress(users[0], 9);
        assertEq(gobblers.ownerOf(10), address(team));
    }

    /*//////////////////////////////////////////////////////////////
                           LEADER GOBBLERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that attempting to mint before start time reverts.
    function testLeaderGobblerMintBeforeStart() public {
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(users[0]);
        gobblers.mintLeaderGobbler(ids);
    }

    /// @notice Test that Leader Gobbler initial price is what we expect.
    function testLeaderGobblerInitialPrice() public {
        // start of initial auction
        vm.warp(block.timestamp + 30 days);
        uint256 cost = gobblers.leaderGobblerPrice();
        // initial auction should start at a cost of 100
        assertEq(cost, 100);
    }

    /// @notice Test that auction ends at a price of 0.
    function testLeaderGobblerFinalPrice() public {
        //30 days for initial auction start, 40 days after initial auction
        vm.warp(block.timestamp + 70 days);
        uint256 cost = gobblers.leaderGobblerPrice();
        // auction price should be 0 after more than 30 days have passed
        assertEq(cost, 0);
    }

    /// @notice Test that mid price happens when we expect.
    function testLeaderGobblerMidPrice() public {
        //30 days for initial auction start, 15 days after initial auction
        vm.warp(block.timestamp + 45 days);
        uint256 cost = gobblers.leaderGobblerPrice();
        // auction price should be 50 mid way through auction
        assertEq(cost, 50);
    }

    /// @notice Test that initial price doens't fall below what we expect.
    function testLeaderGobblerMinStartPrice() public {
        //30 days for initial auction start, 15 days after initial auction
        vm.warp(block.timestamp + 60 days);
        vm.prank(users[0]);
        //empty id list
        uint256[] memory _ids;
        gobblers.mintLeaderGobbler(_ids);
        uint256 startCost = gobblers.leaderGobblerPrice();
        // next gobbler should start at a price of 100
        assertEq(startCost, 100);
    }

    /// @notice Test that Leader Gobblers can be minted.
    function testMintLeaderGobbler() public {
        uint256 startTime = block.timestamp + 30 days;
        vm.warp(startTime);
        uint256 cost = gobblers.leaderGobblerPrice();
        assertEq(cost, 100);
        mintGobblerToAddress(users[0], cost);
        setRandomnessAndReveal(cost, "seed");
        uint256 emissionMultipleSum;
        uint256 curId = 1;
        while (ids.length < cost) {
            if (curId % 10 != 0) {
                ids.push(curId);
                assertEq(gobblers.ownerOf(curId), users[0]);
                emissionMultipleSum += gobblers.getGobblerEmissionMultiple(curId);
            }
            curId++;
        }

        assertEq(gobblers.getUserEmissionMultiple(users[0]), emissionMultipleSum);

        vm.prank(users[0]);
        gobblers.mintLeaderGobbler(ids);
        (, , uint16 currentLeaderId) = gobblers.leaderGobblerAuctionData();

        // Leader is owned by user.
        assertEq(gobblers.ownerOf(currentLeaderId), users[0]);
        assertEq(gobblers.getUserEmissionMultiple(users[0]), emissionMultipleSum * 2);
        assertEq(gobblers.getGobblerEmissionMultiple(currentLeaderId), emissionMultipleSum * 2);

        for (uint256 i = 0; i < ids.length; i++) assertEq(gobblers.ownerOf(ids[i]), address(0));
    }

    /// @notice Test that Leader Gobblers can't be burned to mint another leader.
    function testCannotMintLeaderWithLeader() public {
        vm.warp(block.timestamp + 70 days);
        vm.prank(users[0]);
        gobblers.mintLeaderGobbler(ids);
        (, , uint16 leaderId) = gobblers.leaderGobblerAuctionData();
        assertEq(leaderId, 9991);
        uint256 cost = gobblers.leaderGobblerPrice();
        assertEq(cost, 66);
        mintGobblerToAddress(users[0], cost);
        setRandomnessAndReveal(cost, "seed");
        for (uint256 i = 1; i <= cost; i++) ids.push(i);

        ids[0] = leaderId; // the leader we minted
        vm.prank(users[0]);
        vm.expectRevert(ArtGobblers.CannotBurnLeader.selector);
        gobblers.mintLeaderGobbler(ids);
    }

    /*//////////////////////////////////////////////////////////////
                                  URIS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test unminted URI is correct.
    function testUnmintedUri() public {
        assertEq(gobblers.uri(1), "");
    }

    /// @notice Test that unrevealed URI is correct.
    function testUnrevealedUri() public {
        uint256 gobblerCost = gobblers.gobblerPrice();
        vm.prank(address(gobblers));
        goop.mintForGobblers(users[0], gobblerCost);
        vm.prank(users[0]);
        gobblers.mintFromGoop();
        // assert gobbler not revealed after mint
        assertTrue(stringEquals(gobblers.uri(1), gobblers.UNREVEALED_URI()));
    }

    /// @notice Test that revealed URI is correct.
    function testRevealedUri() public {
        mintGobblerToAddress(users[0], 1);
        // unrevealed gobblers have 0 value attributes
        assertEq(gobblers.getGobblerEmissionMultiple(1), 0);
        vm.warp(block.timestamp + 1 days);
        setRandomnessAndReveal(1, "seed");
        (, uint48 expectedIndex, ) = gobblers.getGobblerData(1);
        string memory expectedURI = string(abi.encodePacked(gobblers.BASE_URI(), uint256(expectedIndex).toString()));
        assertTrue(stringEquals(gobblers.uri(1), expectedURI));
    }

    /// @notice Test that leader gobbler URI is correct.
    function testMintedLeaderURI() public {
        //mint leader
        vm.warp(block.timestamp + 70 days);
        uint256[] memory _ids; // gobbler should be free at this point
        gobblers.mintLeaderGobbler(_ids);
        (, , uint16 currentLeaderId) = gobblers.leaderGobblerAuctionData();

        //expected URI should not be shuffled
        string memory expectedURI = string(abi.encodePacked(gobblers.BASE_URI(), uint256(currentLeaderId).toString()));
        string memory actualURI = gobblers.uri(currentLeaderId);
        assertTrue(stringEquals(actualURI, expectedURI));
    }

    /// @notice Test that un-minted leader gobbler URI is correct
    function testUnmintedLeaderUri() public {
        (, , uint16 currentLeaderId) = gobblers.leaderGobblerAuctionData();

        uint256 leaderId = currentLeaderId + 1;
        assertEq(gobblers.uri(leaderId), "");
    }

    /*//////////////////////////////////////////////////////////////
                                 REVEALS
    //////////////////////////////////////////////////////////////*/

    /// @notice cannot request random seed before 24 hours have passed from initial mint
    function testRevealDelayInitialMint() public {
        mintGobblerToAddress(users[0], 1);
        vm.expectRevert(ArtGobblers.Unauthorized.selector);
        gobblers.getRandomSeed();
    }

    /// @notice cannot request random seed before 24 hours have passed from last reveal
    function testRevealDelayRecurring() public {
        // Mint and reveal first gobbler
        mintGobblerToAddress(users[0], 1);
        vm.warp(block.timestamp + 1 days);
        setRandomnessAndReveal(1, "seed");
        // Attempt reveal before 24 hours have passed
        mintGobblerToAddress(users[0], 1);
        vm.expectRevert(ArtGobblers.Unauthorized.selector);
        gobblers.getRandomSeed();
    }

    /// @notice Test that seed can't be set without first revealing pending gobblers
    function testCantSetRandomSeedWithoutRevealing() public {
        mintGobblerToAddress(users[0], 2);
        vm.warp(block.timestamp + 1 days);
        setRandomnessAndReveal(1, "seed");
        // should fail since there is one remaining gobbler to be revealed with seed
        vm.expectRevert(ArtGobblers.Unauthorized.selector);
        setRandomnessAndReveal(1, "seed");
    }

    /// @notice Test that revevals work as expected
    function testMultiReveal() public {
        mintGobblerToAddress(users[0], 100);
        // first 100 gobblers should be unrevealed
        for (uint256 i = 1; i <= 100; i++) {
            assertEq(gobblers.uri(i), gobblers.UNREVEALED_URI());
        }

        vm.warp(block.timestamp + 1 days); // can only reveal every 24 hours

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

    /*//////////////////////////////////////////////////////////////
                                  GOOP
    //////////////////////////////////////////////////////////////*/

    /// @notice test that goop balance grows as expected.
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

    /// @notice Test that goop removal works as expected.
    function testGoopRemoval() public {
        mintGobblerToAddress(users[0], 1);
        vm.warp(block.timestamp + 1 days);
        setRandomnessAndReveal(1, "seed");
        vm.warp(block.timestamp + 100000);
        uint256 initialBalance = gobblers.goopBalance(users[0]);
        uint256 removalAmount = initialBalance / 10; //10%
        vm.prank(users[0]);
        gobblers.removeGoop(removalAmount);
        uint256 finalBalance = gobblers.goopBalance(users[0]);
        // balance should change
        assertTrue(initialBalance != finalBalance);
        assertEq(initialBalance, finalBalance + removalAmount);
        // user should have removed goop
        assertEq(goop.balanceOf(users[0]), removalAmount);
    }

    /// @notice Test that goop can't be removed by a different user.
    function testCantRemoveGoop() public {
        mintGobblerToAddress(users[0], 1);
        vm.warp(block.timestamp + 100000);
        setRandomnessAndReveal(1, "seed");
        vm.prank(users[1]);
        vm.expectRevert(stdError.arithmeticError);
        gobblers.removeGoop(1);
    }

    /// @notice Test that adding goop is reflected in balance.
    function testGoopAddition() public {
        mintGobblerToAddress(users[0], 1);
        assertEq(gobblers.getGobblerEmissionMultiple(1), 0);
        assertEq(gobblers.getUserEmissionMultiple(users[0]), 0);
        // waiting after mint to reveal shouldn't affect balance
        vm.warp(block.timestamp + 100000);
        assertEq(gobblers.goopBalance(users[0]), 0);
        setRandomnessAndReveal(1, "seed");
        uint256 gobblerMultiple = gobblers.getGobblerEmissionMultiple(1);
        assertGt(gobblerMultiple, 0);
        assertEq(gobblers.getUserEmissionMultiple(users[0]), gobblerMultiple);
        vm.prank(address(gobblers));
        uint256 additionAmount = 1000;
        goop.mintForGobblers(users[0], additionAmount);
        vm.prank(users[0]);
        gobblers.addGoop(additionAmount);
        assertEq(gobblers.goopBalance(users[0]), additionAmount);
    }

    /// @notice Test that emission multiple changes as expected after transfer.
    function testEmissionMultipleUpdatesAfterTransfer() public {
        mintGobblerToAddress(users[0], 1);
        vm.warp(block.timestamp + 1 days);
        setRandomnessAndReveal(1, "seed");

        uint256 initialUserMultiple = gobblers.getUserEmissionMultiple(users[0]);
        assertGt(initialUserMultiple, 0);
        assertEq(gobblers.getUserEmissionMultiple(users[1]), 0);

        vm.prank(users[0]);
        gobblers.safeTransferFrom(users[0], users[1], 1, 1, "");

        assertEq(gobblers.getUserEmissionMultiple(users[0]), 0);
        assertEq(gobblers.getUserEmissionMultiple(users[1]), initialUserMultiple);
    }

    /// @notice Test that gobbler balances are accurate after transfer.
    function testGobblerBalancesAfterTransfer() public {
        mintGobblerToAddress(users[0], 1);
        vm.warp(block.timestamp + 1 days);
        setRandomnessAndReveal(1, "seed");

        vm.warp(block.timestamp + 1000000);

        uint256 userOneBalance = gobblers.goopBalance(users[0]);
        uint256 userTwoBalance = gobblers.goopBalance(users[1]);
        //user with gobbler should have non-zero balance
        assertGt(userOneBalance, 0);
        //other user should have zero balance
        assertEq(userTwoBalance, 0);
        //transfer gobblers
        vm.prank(users[0]);
        gobblers.safeTransferFrom(users[0], users[1], 1, 1, "");
        //balance should not change after transfer
        assertEq(gobblers.goopBalance(users[0]), userOneBalance);
        assertEq(gobblers.goopBalance(users[1]), userTwoBalance);
    }

    /*//////////////////////////////////////////////////////////////
                               FEEDING ART
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that pages can be fed to gobblers.
    function testFeedingArt() public {
        address user = users[0];
        mintGobblerToAddress(user, 1);
        uint256 pagePrice = pages.pagePrice();
        vm.prank(address(gobblers));
        goop.mintForGobblers(user, pagePrice);
        vm.startPrank(user);
        pages.mint();
        gobblers.feedArt(1, address(pages), 1);
        vm.stopPrank();
        assertEq(gobblers.getGobblerFromFedArt(address(pages), 1), 1);
    }

    /// @notice Test that you can't feed art to gobblers you don't own.
    function testCantFeedArtToUnownedGobbler() public {
        address user = users[0];
        uint256 pagePrice = pages.pagePrice();
        vm.prank(address(gobblers));
        goop.mintForGobblers(user, pagePrice);
        vm.startPrank(user);
        pages.mint();
        vm.expectRevert(ArtGobblers.Unauthorized.selector);
        gobblers.feedArt(1, address(pages), 1);
        vm.stopPrank();
    }

    /// @notice Test that you can't feed art you don't own to your gobbler.
    function testCantFeedUnownedArt() public {
        address user = users[0];
        mintGobblerToAddress(user, 1);
        vm.startPrank(user);
        vm.expectRevert("WRONG_FROM");
        gobblers.feedArt(1, address(pages), 1);
        vm.stopPrank();
    }

    /// @notice Test that you can't feed art twice.
    function testCantFeedArtTwice() public {
        MockERC1155 token = new MockERC1155();
        address user = users[0];
        mintGobblerToAddress(user, 1);
        token.mint(user, 1, 2, "");
        vm.startPrank(user);
        token.setApprovalForAll(address(gobblers), true);
        gobblers.feedArt(1, address(token), 1);
        vm.expectRevert(ArtGobblers.AlreadyEaten.selector);
        gobblers.feedArt(1, address(token), 1);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                           LONG-RUNNING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check that max supply is mintable
    function testLongRunningMintMaxFromGoop() public {
        //max_supply - leaders - mintlist - team
        uint256 maxMintableWithGoop = gobblers.MAX_SUPPLY() -
            gobblers.MINTLIST_SUPPLY() -
            gobblers.LEADER_SUPPLY() -
            gobblers.TEAM_SUPPLY();
        for (uint256 i = 0; i < maxMintableWithGoop; i++) {
            vm.warp(block.timestamp + 1 days);
            uint256 cost = gobblers.gobblerPrice();
            vm.prank(address(gobblers));
            goop.mintForGobblers(users[0], cost);
            vm.prank(users[0]);
            gobblers.mintFromGoop();
        }
    }

    // TODO: THIS TEST SHOULD REVERT
    // /// @notice Check that minting beyond max supply should revert .
    //  function testLongRunningMintMaxFromGoopRevert() public {
    //     //max_supply - leaders - mintlist - team
    //     uint256 maxMintableWithGoop = gobblers.MAX_SUPPLY() - gobblers.MINTLIST_SUPPLY() - gobblers.LEADER_SUPPLY() - gobblers.TEAM_SUPPLY();
    //     for (uint256 i = 0; i < maxMintableWithGoop + 1; i++) {
    //         vm.warp(block.timestamp + 1 days);
    //         uint256 cost = gobblers.gobblerPrice();
    //         vm.prank(address(gobblers));
    //         goop.mintForGobblers(users[0], cost);
    //         vm.prank(users[0]);
    //         gobblers.mintFromGoop();
    //     }
    // }

    // /// @notice Test whether all ids are assigned after full reveal.
    // function testLongRunningAllIdsUnique() public {
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

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice  Mint a number of gobblers to the given address
    function mintGobblerToAddress(address addr, uint256 num) internal {
        for (uint256 i = 0; i < num; i++) {
            vm.startPrank(address(gobblers));
            goop.mintForGobblers(addr, gobblers.gobblerPrice());
            vm.stopPrank();

            vm.prank(addr);
            gobblers.mintFromGoop();
        }
    }

    /// @notice Call back vrf with randomness and reveal gobblers.
    function setRandomnessAndReveal(uint256 numReveal, string memory seed) internal {
        bytes32 requestId = gobblers.getRandomSeed();
        uint256 randomness = uint256(keccak256(abi.encodePacked(seed)));
        // call back from coordinator
        vrfCoordinator.callBackWithRandomness(requestId, randomness, address(gobblers));
        gobblers.revealGobblers(numReveal);
    }

    /// @notice Check for string equality.
    function stringEquals(string memory s1, string memory s2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}
