// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockGoopCalculator} from "../utils/mocks/MockGoopCalculator.sol";
import {Vm} from "forge-std/Vm.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract EmissionCorrectnessTest is DSTestPlus {
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    MockGoopCalculator goopCalculator = new MockGoopCalculator();

    function testFFIEmissionCorrectness(
        uint256 daysElapsedWad,
        uint256 lastBalanceWad,
        uint256 emissionMultiple
    ) public {
        emissionMultiple = bound(emissionMultiple, 0, 100);

        daysElapsedWad = bound(daysElapsedWad, 0, 720 days * 1e18);

        lastBalanceWad = bound(lastBalanceWad, 0, 1e36);

        uint256 expectedBalance = calculateBalance(daysElapsedWad, lastBalanceWad, emissionMultiple);

        uint256 actualBalance = goopCalculator.computeGoopBalance(emissionMultiple, lastBalanceWad, daysElapsedWad);

        // Equal within 1 percent.
        assertRelApproxEq(actualBalance, expectedBalance, 0.01e18);
    }

    function calculateBalance(
        uint256 _emissionTime,
        uint256 _initialAmount,
        uint256 _emissionMultiple
    ) private returns (uint256) {
        string[] memory inputs = new string[](8);
        inputs[0] = "python3";
        inputs[1] = "analysis/compute_emissions.py";
        inputs[2] = "--time";
        inputs[3] = _emissionTime.toString();
        inputs[4] = "--initial_amount";
        inputs[5] = _initialAmount.toString();
        inputs[6] = "--emission_multiple";
        inputs[7] = _emissionMultiple.toString();

        return abi.decode(vm.ffi(inputs), (uint256));
    }
}
