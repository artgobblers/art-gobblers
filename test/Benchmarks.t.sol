// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ArtGobblers} from "../src/ArtGobblers.sol";
import {RandProvider} from "../src/utils/rand/RandProvider.sol";
import {ChainlinkV1RandProvider} from "../src/utils/rand/ChainlinkV1RandProvider.sol";
import {Goo} from "../src/Goo.sol";
import {Pages} from "../src/Pages.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";

contract BenchmarksTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    VRFCoordinatorMock private vrfCoordinator;
    LinkToken private linkToken;
    RandProvider private randProvider;
    Goo private goo;
    Pages private pages;

    uint256 legendaryCost;

    bytes32 private keyHash;
    uint256 private fee;

    function setUp() public {
        vm.warp(1); // Otherwise mintStart will be set to 0 and brick pages.mintFromGoo(type(uint256).max)

        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));

        //gobblers contract will be deployed after 2 contract deploys, and pages after 3
        address gobblerAddress = utils.predictContractAddress(address(this), 2);
        address pageAddress = utils.predictContractAddress(address(this), 3);

        randProvider = new ChainlinkV1RandProvider(
            ArtGobblers(gobblerAddress),
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee
        );

        goo = new Goo(gobblerAddress, pageAddress);

        gobblers = new ArtGobblers(
            keccak256(abi.encodePacked(users[0])),
            block.timestamp,
            goo,
            Pages(pageAddress),
            address(0xBEEF),
            address(0xBEEF),
            randProvider,
            "base",
            ""
        );

        pages = new Pages(block.timestamp, goo, address(0xBEEF), gobblers, "");

        vm.prank(address(gobblers));
        goo.mintForGobblers(address(this), type(uint192).max);

        gobblers.addGoo(type(uint96).max);

        mintPageToAddress(address(this), 9);
        mintGobblerToAddress(address(this), gobblers.LEGENDARY_AUCTION_INTERVAL());

        vm.warp(block.timestamp + 30 days);

        legendaryCost = gobblers.legendaryGobblerPrice();

        bytes32 requestId = gobblers.requestRandomSeed();
        uint256 randomness = uint256(keccak256(abi.encodePacked("seed")));
        vrfCoordinator.callBackWithRandomness(requestId, randomness, address(randProvider));
    }

    function testPagePrice() public view {
        pages.pagePrice();
    }

    function testGobblerPrice() public view {
        gobblers.gobblerPrice();
    }

    function testLegendaryGobblersPrice() public view {
        gobblers.legendaryGobblerPrice();
    }

    function testGooBalance() public view {
        gobblers.gooBalance(address(this));
    }

    function testMintPage() public {
        pages.mintFromGoo(type(uint256).max, false);
    }

    function testMintPageUsingVirtualBalance() public {
        pages.mintFromGoo(type(uint256).max, true);
    }

    function testMintGobbler() public {
        gobblers.mintFromGoo(type(uint256).max, false);
    }

    function testMintGobblerUsingVirtualBalance() public {
        gobblers.mintFromGoo(type(uint256).max, true);
    }

    function testTransferGobbler() public {
        gobblers.transferFrom(address(this), address(0xBEEF), 1);
    }

    function testAddGoo() public {
        gobblers.addGoo(1e18);
    }

    function testRemoveGoo() public {
        gobblers.removeGoo(1e18);
    }

    function testRevealGobblers() public {
        gobblers.revealGobblers(100);
    }

    function testMintLegendaryGobbler() public {
        uint256 legendaryGobblerCost = legendaryCost;

        uint256[] memory ids = new uint256[](legendaryGobblerCost);
        for (uint256 i = 0; i < legendaryGobblerCost; i++) ids[i] = i + 1;

        gobblers.mintLegendaryGobbler(ids);
    }

    function testMintReservedGobblers() public {
        gobblers.mintReservedGobblers(1);
    }

    function testMintCommunityPages() public {
        pages.mintCommunityPages(1);
    }

    function mintGobblerToAddress(address addr, uint256 num) internal {
        for (uint256 i = 0; i < num; i++) {
            vm.startPrank(address(gobblers));
            goo.mintForGobblers(addr, gobblers.gobblerPrice());
            vm.stopPrank();

            vm.prank(addr);
            gobblers.mintFromGoo(type(uint256).max, false);
        }
    }

    function mintPageToAddress(address addr, uint256 num) internal {
        for (uint256 i = 0; i < num; i++) {
            vm.startPrank(address(gobblers));
            goo.mintForGobblers(addr, pages.pagePrice());
            vm.stopPrank();

            vm.prank(addr);
            pages.mintFromGoo(type(uint256).max, false);
        }
    }
}
