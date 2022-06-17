// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {LibString} from "../../utils/LibString.sol";
import {ArtGobblers} from "../../ArtGobblers.sol";
import {Goo} from "../../Goo.sol";

contract GobblersCorrectnessTest is DSTestPlus {
    using LibString for uint256;

    uint256 internal immutable FIVE_YEARS = 365 days * 5;

    uint256 internal MAX_MINTABLE;

    int256 internal LOGISTIC_SCALE;

    int256 internal immutable INITIAL_PRICE = 6.9e18;

    int256 internal immutable PER_PERIOD_PRICE_DECREASE = 0.31e18;

    int256 internal immutable TIME_SCALE = 0.014e18;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    ArtGobblers internal gobblers;

    function setUp() public {
        gobblers = new ArtGobblers(
            "root",
            block.timestamp,
            Goo(address(0)),
            address(0),
            address(0),
            address(0),
            address(0),
            0,
            0,
            "",
            ""
        );

        MAX_MINTABLE = gobblers.MAX_MINTABLE();
        LOGISTIC_SCALE = int256(MAX_MINTABLE * 2e18);
    }

    function testFFICorrectness(uint256 timeSinceStart, uint256 numSold) public {
        // Limit num sold to max mint.
        numSold = bound(numSold, 0, MAX_MINTABLE);

        // Limit mint time to 5 years.
        timeSinceStart = bound(timeSinceStart, 0, FIVE_YEARS);

        // Calculate actual price from VRGDA.
        try gobblers.getPrice(timeSinceStart, numSold) returns (uint256 actualPrice) {
            // Calculate expected price from python script.
            uint256 expectedPrice = calculatePrice(
                timeSinceStart,
                numSold,
                INITIAL_PRICE,
                PER_PERIOD_PRICE_DECREASE,
                LOGISTIC_SCALE,
                TIME_SCALE
            );

            if (expectedPrice < 10) return; // For really small prices we can't expect them to be equal.

            // Equal within 1 percent.
            assertRelApproxEq(actualPrice, expectedPrice, 0.01e18);
        } catch {
            // If it reverts that's fine, there are some bounds on the function, they are tested in VRGDAs.t.sol
        }
    }

    function calculatePrice(
        uint256 _timeSinceStart,
        uint256 _numSold,
        int256 _initialPrice,
        int256 _perPeriodPriceDecrease,
        int256 _logisticScale,
        int256 _timeScale
    ) private returns (uint256) {
        string[] memory inputs = new string[](15);
        inputs[0] = "python3";
        inputs[1] = "analysis/compute_price.py";
        inputs[2] = "gobblers";
        inputs[3] = "--time_since_start";
        inputs[4] = _timeSinceStart.toString();
        inputs[5] = "--num_sold";
        inputs[6] = _numSold.toString();
        inputs[7] = "--initial_price";
        inputs[8] = uint256(_initialPrice).toString();
        inputs[9] = "--per_period_price_decrease";
        inputs[10] = uint256(_perPeriodPriceDecrease).toString();
        inputs[11] = "--logistic_scale";
        inputs[12] = uint256(_logisticScale).toString();
        inputs[13] = "--time_scale";
        inputs[14] = uint256(_timeScale).toString();

        return abi.decode(vm.ffi(inputs), (uint256));
    }
}
