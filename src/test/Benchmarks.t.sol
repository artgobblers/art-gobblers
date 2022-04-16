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

    bytes32 private keyHash;
    uint256 private fee;
    string private baseUri = "base";

    function setUp() public {
        // avoid starting at timestamp = 0 for ease of testing
        vm.warp(block.timestamp + 1);

        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));
        gobblers = new ArtGobblers(
            "root",
            block.timestamp,
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

        pages.mint();

        gobblers.addGoop(1e18);

        vm.warp(block.timestamp + 30 days);

        for (uint256 i = 0; i < 100; i++) gobblers.mintFromGoop();
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
        gobblers.mintFromGoop();
    }

    function testAddGoop() public {
        gobblers.addGoop(1e18);
    }

    function testRemoveGoop() public {
        gobblers.removeGoop(1e18);
    }

    function testFeedArt() public {
        gobblers.feedArt(1, address(pages), 1);
    }

    function testMintLegendaryGobbler() public {
        uint256[] memory ids = new uint256[](100);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;
        ids[3] = 4;
        ids[4] = 5;
        ids[5] = 6;
        ids[6] = 7;
        ids[7] = 8;
        ids[8] = 9;
        ids[9] = 10;
        ids[10] = 11;
        ids[11] = 12;
        ids[12] = 13;
        ids[13] = 14;
        ids[14] = 15;
        ids[15] = 16;
        ids[16] = 17;
        ids[17] = 18;
        ids[18] = 19;
        ids[19] = 20;
        ids[20] = 21;
        ids[21] = 22;
        ids[22] = 23;
        ids[23] = 24;
        ids[24] = 25;
        ids[25] = 26;
        ids[26] = 27;
        ids[27] = 28;
        ids[28] = 29;
        ids[29] = 30;
        ids[30] = 31;
        ids[31] = 32;
        ids[32] = 33;
        ids[33] = 34;
        ids[34] = 35;
        ids[35] = 36;
        ids[36] = 37;
        ids[37] = 38;
        ids[38] = 39;
        ids[39] = 40;
        ids[40] = 41;
        ids[41] = 42;
        ids[42] = 43;
        ids[43] = 44;
        ids[44] = 45;
        ids[45] = 46;
        ids[46] = 47;
        ids[47] = 48;
        ids[48] = 49;
        ids[49] = 50;
        ids[50] = 51;
        ids[51] = 52;
        ids[52] = 53;
        ids[53] = 54;
        ids[54] = 55;
        ids[55] = 56;
        ids[56] = 57;
        ids[57] = 58;
        ids[58] = 59;
        ids[59] = 60;
        ids[60] = 61;
        ids[61] = 62;
        ids[62] = 63;
        ids[63] = 64;
        ids[64] = 65;
        ids[65] = 66;
        ids[66] = 67;
        ids[67] = 68;
        ids[68] = 69;
        ids[69] = 70;
        ids[70] = 71;
        ids[71] = 72;
        ids[72] = 73;
        ids[73] = 74;
        ids[74] = 75;
        ids[75] = 76;
        ids[76] = 77;
        ids[77] = 78;
        ids[78] = 79;
        ids[79] = 80;
        ids[80] = 81;
        ids[81] = 82;
        ids[82] = 83;
        ids[83] = 84;
        ids[84] = 85;
        ids[85] = 86;
        ids[86] = 87;
        ids[87] = 88;
        ids[88] = 89;
        ids[89] = 90;
        ids[90] = 91;
        ids[91] = 92;
        ids[92] = 93;
        ids[93] = 94;
        ids[94] = 95;
        ids[95] = 96;
        ids[96] = 97;
        ids[97] = 98;
        ids[98] = 99;
        ids[99] = 100;

        gobblers.mintLegendaryGobbler(ids);
    }
}
