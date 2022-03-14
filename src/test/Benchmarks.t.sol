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
import {Strings} from "openzeppelin/utils/Strings.sol";

contract BenchmarksTest is DSTest {
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

    function setUp() public {
        vm.warp(1); // Otherwise mintStart will be set to 0 and brick Pages.mint()

        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        gobblers = new ArtGobblers(address(vrfCoordinator), address(linkToken), keyHash, fee, baseUri);
        goop = gobblers.goop();
        pages = gobblers.pages();

        vm.prank(address(gobblers));
        goop.mint(address(this), type(uint128).max);

        gobblers.setMerkleRoot("root");
        gobblers.mintFromGoop();

        pages.mint(); // Initialize the page storage slots.

        vm.warp(block.timestamp + 60 days); // Long enough for legendary gobblers to be free.
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
        gobblers.goopBalance(1);
    }

    function testMintPage() public {
        pages.mint();
    }

    function testMintGobbler() public {
        gobblers.mintFromGoop();
    }

    function testMintLegendaryGobbler() public {
        uint256[] memory ids;

        gobblers.mintLegendaryGobbler(ids);
    }

    function testAddAndRemoveGoop() public {
        gobblers.addGoop(1, 1e18);
        gobblers.removeGoop(1, 1e18);
    }
}
