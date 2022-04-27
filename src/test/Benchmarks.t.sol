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
import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";
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
        vm.warp(1); // Otherwise mintStart will be set to 0 and brick Pages.mint()

        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));

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
            address(0xBEEF),
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            baseUri
        );

        pages = new Pages(block.timestamp, address(gobblers), goop);

        vm.prank(address(gobblers));
        goop.mintForGobblers(address(this), type(uint128).max);

        pages.mint();

        gobblers.addGoop(1e18);

        vm.warp(block.timestamp + 30 days);

        for (uint256 i = 0; i < 100; i++) gobblers.mintFromGoop();

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

    function testLeaderGobblersPrice() public view {
        gobblers.leaderGobblerPrice();
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

    function testRevealGobblers() public {
        gobblers.revealGobblers(100);
    }

    function testMintLeaderGobbler() public {
        // We skip every 9 ids because
        // of the team gobbler mints.
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
        ids[9] = 11;
        ids[10] = 12;
        ids[11] = 13;
        ids[12] = 14;
        ids[13] = 15;
        ids[14] = 16;
        ids[15] = 17;
        ids[16] = 18;
        ids[17] = 19;
        ids[18] = 21;
        ids[19] = 22;
        ids[20] = 23;
        ids[21] = 24;
        ids[22] = 25;
        ids[23] = 26;
        ids[24] = 27;
        ids[25] = 28;
        ids[26] = 29;
        ids[27] = 31;
        ids[28] = 32;
        ids[29] = 33;
        ids[30] = 34;
        ids[31] = 35;
        ids[32] = 36;
        ids[33] = 37;
        ids[34] = 38;
        ids[35] = 39;
        ids[36] = 41;
        ids[37] = 42;
        ids[38] = 43;
        ids[39] = 44;
        ids[40] = 45;
        ids[41] = 46;
        ids[42] = 47;
        ids[43] = 48;
        ids[44] = 49;
        ids[45] = 51;
        ids[46] = 52;
        ids[47] = 53;
        ids[48] = 54;
        ids[49] = 55;
        ids[50] = 56;
        ids[51] = 57;
        ids[52] = 58;
        ids[53] = 59;
        ids[54] = 61;
        ids[55] = 62;
        ids[56] = 63;
        ids[57] = 64;
        ids[58] = 65;
        ids[59] = 66;
        ids[60] = 67;
        ids[61] = 68;
        ids[62] = 69;
        ids[63] = 71;
        ids[64] = 72;
        ids[65] = 73;
        ids[66] = 74;
        ids[67] = 75;
        ids[68] = 76;
        ids[69] = 77;
        ids[70] = 78;
        ids[71] = 79;
        ids[72] = 81;
        ids[73] = 82;
        ids[74] = 83;
        ids[75] = 84;
        ids[76] = 85;
        ids[77] = 86;
        ids[78] = 87;
        ids[79] = 88;
        ids[80] = 89;
        ids[81] = 91;
        ids[82] = 92;
        ids[83] = 93;
        ids[84] = 94;
        ids[85] = 95;
        ids[86] = 96;
        ids[87] = 97;
        ids[88] = 98;
        ids[89] = 99;
        ids[90] = 101;
        ids[91] = 102;
        ids[92] = 103;
        ids[93] = 104;
        ids[94] = 105;
        ids[95] = 106;
        ids[96] = 107;
        ids[97] = 108;
        ids[98] = 109;
        ids[99] = 111;

        gobblers.mintLeaderGobbler(ids);
    }
}
