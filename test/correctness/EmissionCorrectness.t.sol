// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockGooCalculator} from "../utils/mocks/MockGooCalculator.sol";
import {Vm} from "forge-std/Vm.sol";
import {LibString} from "../../src/utils/LibString.sol";

contract EmissionCorrectnessTest is DSTestPlus {
    using LibString for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    MockGooCalculator immutable gooCalculator = new MockGooCalculator();

    function testFFIEmissionCorrectness(
        uint256 daysElapsedWad,
        uint256 lastBalanceWad,
        uint256 emissionMultiple
    ) public {
        emissionMultiple = bound(emissionMultiple, 0, 100);

        daysElapsedWad = bound(daysElapsedWad, 0, 7300 days * 1e18);

        lastBalanceWad = bound(lastBalanceWad, 0, 1e36);

        uint256 expectedBalance = calculateBalance(daysElapsedWad, lastBalanceWad, emissionMultiple);

        uint256 actualBalance = gooCalculator.computeGooBalance(emissionMultiple, lastBalanceWad, daysElapsedWad);

        if (expectedBalance < 0.0000000000001e18) return; // For really small balances we can't expect them to be equal.

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
