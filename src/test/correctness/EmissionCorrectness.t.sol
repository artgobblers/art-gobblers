// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {Utilities} from "../utils/Utilities.sol";
import {console} from "../utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/Test.sol";
import {ArtGobblers} from "../../ArtGobblers.sol";
import {Goop} from "../../Goop.sol";
import {Pages} from "../../Pages.sol";
import {ERC1155BLockupVault} from "../../utils/ERC1155BLockupVault.sol";
import {LinkToken} from "../utils/mocks/LinkToken.sol";
import {VRFCoordinatorMock} from "chainlink/v0.8/mocks/VRFCoordinatorMock.sol";
import {MockERC1155} from "solmate/test/utils/mocks/MockERC1155.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract EmissionCorrectnessTest is DSTestPlus {
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

    function testFFIEmissionCorrectness(
        uint256 daysElapsedWad,
        uint256 lastBalanceWad,
        uint256 emissionMultiple
    ) public {
        emissionMultiple = bound(emissionMultiple, 0, 100);

        daysElapsedWad = bound(daysElapsedWad, 0, 720 days * 1e18);

        lastBalanceWad = bound(lastBalanceWad, 0, 1e36);

        uint256 expectedBalance = calculateBalance(daysElapsedWad, lastBalanceWad, emissionMultiple);

        uint256 actualBalance = gobblers.computeGoopBalance(emissionMultiple, lastBalanceWad, daysElapsedWad);

        // Equal within 1 percent.
        assertRelApproxEq(expectedBalance, actualBalance, 0.01e18);
    }

    function calculateBalance(
        uint256 _emmisionTime,
        uint256 _initialAmount,
        uint256 _emissionMultiple
    ) private returns (uint256) {
        string[] memory inputs = new string[](8);
        inputs[0] = "python3";
        inputs[1] = "analysis/compute_emissions.py";
        inputs[2] = "--time";
        inputs[3] = _emmisionTime.toString();
        inputs[4] = "--initial_amount";
        inputs[5] = _initialAmount.toString();
        inputs[6] = "--emission_multiple";
        inputs[7] = _emissionMultiple.toString();

        return abi.decode(vm.ffi(inputs), (uint256));
    }
}
