// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ArtGobblers} from "../ArtGobblers.sol";
import {Goop} from "../Goop.sol";
import {Pages} from "../Pages.sol";
import {LockupVault} from "../LockupVault.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "./utils/mocks/VRFCoordinatorMock.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract BenchmarksTest is DSTest, ERC1155TokenReceiver {
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers private gobblers;
    VRFCoordinatorMock private vrfCoordinator;
    LinkToken private linkToken;

    Goop goop;
    Pages pages;
    LockupVault vault;

    bytes32 private keyHash;
    uint256 private fee;
    string private baseUri = "base";

    function setUp() public {
        vm.warp(1); // Otherwise mintStart will be set to 0 and brick Pages.mint()

        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        vault = new LockupVault();

        gobblers = new ArtGobblers(
            "root",
            block.timestamp,
            address(vault),
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            baseUri
        );
        goop = gobblers.goop();
        pages = gobblers.pages();

        vm.prank(address(gobblers));
        goop.mint(address(this), type(uint128).max);

        gobblers.mintFromGoop();

        // TODO: remove this and do in the legendary gobbler benchmark
        vm.warp(block.timestamp + 60 days); // Long enough for legendary gobblers to be free.

        gobblers.addGoop(1e18);
    }

    // TODO: benchmark large legendary gobbler mint

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
        gobblers.mintFromGoop();
    }

    function testMintLegendaryGobbler() public {
        uint256[] memory ids;

        gobblers.mintLegendaryGobbler(ids);
    }

    function testAddGoop() public {
        gobblers.addGoop(1e18);
    }

    function testRemoveGoop() public {
        gobblers.removeGoop(1e18);
    }
}
