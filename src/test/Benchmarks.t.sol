// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ArtGobblers} from "../ArtGobblers.sol";
import {Goo} from "../Goo.sol";
import {Pages} from "../Pages.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";

contract BenchmarksTest is DSTest, ERC1155TokenReceiver {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    VRFCoordinatorMock private vrfCoordinator;
    LinkToken private linkToken;

    Goo goo;
    Pages pages;

    bytes32 private keyHash;
    uint256 private fee;

    function setUp() public {
        vm.warp(1); // Otherwise mintStart will be set to 0 and brick pages.mintFromGoop(type(uint256).max)

        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));

        goo = new Goo(
            // Gobblers:
            utils.predictContractAddress(address(this), 1),
            // Pages:
            utils.predictContractAddress(address(this), 2)
        );

        gobblers = new ArtGobblers(
            keccak256(abi.encodePacked(users[0])),
            block.timestamp,
            goo,
            address(0xBEEF),
            address(0xBEEF),
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            "base",
            ""
        );

        pages = new Pages(block.timestamp, address(gobblers), goo, "");

        vm.prank(address(gobblers));
        goo.mintForGobblers(address(this), type(uint128).max);

        pages.mintFromGoop(type(uint256).max);

        gobblers.addGoop(1e18);

        vm.warp(block.timestamp + 30 days);

        for (uint256 i = 0; i < 100; i++) gobblers.mintFromGoop(type(uint256).max);

        bytes32 requestId = gobblers.getRandomSeed();
        uint256 randomness = uint256(keccak256(abi.encodePacked("seed")));
        vrfCoordinator.callBackWithRandomness(requestId, randomness, address(gobblers));
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

    function testGoopBalance() public view {
        gobblers.gooBalance(address(this));
    }

    function testMintPage() public {
        pages.mintFromGoop(type(uint256).max);
    }

    function testMintGobbler() public {
        gobblers.mintFromGoop(type(uint256).max);
    }

    function testBatchTransferGobblers() public {
        uint256[] memory ids = new uint256[](100);
        uint256[] memory amounts = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            ids[i] = i + 1;
            amounts[i] = 1;
        }

        gobblers.safeBatchTransferFrom(address(this), address(0xBEEF), ids, amounts, "");
    }

    function testAddGoop() public {
        gobblers.addGoop(1e18);
    }

    function testRemoveGoop() public {
        gobblers.removeGoop(1e18);
    }

    function testRevealGobblers() public {
        gobblers.revealGobblers(100);
    }

    function testMintLegendaryGobbler() public {
        uint256[] memory ids = new uint256[](69);
        for (uint256 i = 0; i < 69; i++) ids[i] = i + 1;

        gobblers.mintLegendaryGobbler(ids);
    }
}
