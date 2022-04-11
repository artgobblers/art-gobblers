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
import {MockVRFCoordinatorV2} from "./utils/mocks/MockVRFCoordinatorV2.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

contract BenchmarksTest is DSTest, ERC1155TokenReceiver {
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    MockVRFCoordinatorV2 private vrfCoordinator;
    LinkToken private linkToken;
    Goop goop;
    Pages pages;

    uint96 constant FUND_AMOUNT = 1 * 10**18;

    // Initialized as blank, fine for testing
    uint64 subId;
    bytes32 keyHash; // gasLane

    string private baseUri = "base";

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new MockVRFCoordinatorV2();
        subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);

        gobblers = new ArtGobblers("root", block.timestamp, address(vrfCoordinator), keyHash, subId, baseUri);
        goop = gobblers.goop();
        pages = gobblers.pages();

        vm.prank(address(gobblers));
        goop.mint(address(this), type(uint128).max);

        gobblers.mintFromGoop();
        pages.mint();

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
        gobblers.goopBalance(address(this));
    }

    function testMintPage() public {
        pages.mint();
    }

    function testMintGobbler() public {
        // TODO: why is minting a gobbler more expensive than a page?
        gobblers.mintFromGoop();
    }

    function testMintLegendaryGobbler() public {
        uint256[] memory ids;

        gobblers.mintLegendaryGobbler(ids);
    }

    function testAddAndRemoveGoop() public {
        gobblers.addGoop(1e18);
        gobblers.removeGoop(1e18);
    }
}
