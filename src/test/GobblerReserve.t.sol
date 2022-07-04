// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {ArtGobblers} from "../ArtGobblers.sol";
import {Goo} from "../Goo.sol";
import {Pages} from "../Pages.sol";
import {GobblerReserve} from "../utils/GobblerReserve.sol";
import {LinkToken} from "./utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {MockERC1155} from "solmate/test/utils/mocks/MockERC1155.sol";
import {LibString} from "../utils/LibString.sol";

/// @notice Unit test for the Gobbler Reserve contract.
contract GobblerReserveTest is DSTestPlus, ERC1155TokenReceiver {
    using LibString for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    ArtGobblers internal gobblers;
    VRFCoordinatorMock internal vrfCoordinator;
    LinkToken internal linkToken;
    Goo internal goo;
    Pages internal pages;
    GobblerReserve internal team;
    GobblerReserve internal community;

    bytes32 private keyHash;
    uint256 private fee;

    uint256[] ids;

    /*//////////////////////////////////////////////////////////////
                                  SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        linkToken = new LinkToken();
        vrfCoordinator = new VRFCoordinatorMock(address(linkToken));

        team = new GobblerReserve(ArtGobblers(utils.predictContractAddress(address(this), 3)), address(this));
        community = new GobblerReserve(ArtGobblers(utils.predictContractAddress(address(this), 2)), address(this));

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
            address(team),
            address(community),
            address(vrfCoordinator),
            address(linkToken),
            keyHash,
            fee,
            "base",
            ""
        );

        pages = new Pages(block.timestamp, goo, address(0xBEEF), address(gobblers), "");
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that a reserve can be withdrawn from.
    function testCanWithdraw() public {
        mintGobblerToAddress(users[0], 9);

        gobblers.mintReservedGobblers(1);

        assertEq(gobblers.ownerOf(10), address(team));
        assertEq(gobblers.ownerOf(11), address(community));

        uint256[] memory idsToWithdraw = new uint256[](1);

        idsToWithdraw[0] = 10;
        team.withdraw(address(this), idsToWithdraw);

        idsToWithdraw[0] = 11;
        community.withdraw(address(this), idsToWithdraw);

        assertEq(gobblers.ownerOf(10), address(this));
        assertEq(gobblers.ownerOf(11), address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of gobblers to the given address
    function mintGobblerToAddress(address addr, uint256 num) internal {
        for (uint256 i = 0; i < num; i++) {
            vm.startPrank(address(gobblers));
            goo.mintForGobblers(addr, gobblers.gobblerPrice());
            vm.stopPrank();

            vm.prank(addr);
            gobblers.mintFromGoo(type(uint256).max);
        }
    }
}
