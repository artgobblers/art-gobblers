// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {console} from "../utils/Console.sol";
import {Pages} from "../../Pages.sol";
import {Goop} from "../../Goop.sol";

contract PageCorrectnessTest is DSTestPlus {
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 internal immutable MAX_PAGE_MINT = 1000;

    uint256 internal immutable FIVE_YEARS = 5 * 365 days;

    int256 internal immutable INITIAL_PRICE = 4.20e18;

    int256 internal immutable PER_PERIOD_PRICE_DECREASE = 0.31e18;

    int256 internal immutable LOGISTIC_SCALE = (9999 + 1) * 2e18;

    int256 internal immutable TIME_SCALE = 0.023e18;

    int256 internal immutable TIME_SHIFT = 0;

    int256 internal immutable PER_PERIOD_POST_SWITCHOVER = 10e18;

    int256 internal immutable SWITCHOVER_TIME = 207e18;

    Pages internal pages;

    function setUp() public {
        pages = new Pages(block.timestamp, address(0), Goop(address(0)));
    }

    function testFFICorrectness(uint256 timeSinceStart, uint256 numSold) public {
        // Limit num sold to max mint.
        numSold = bound(numSold, 0, 10000);

        // Limit mint time to 5 years.
        timeSinceStart = bound(timeSinceStart, 0, FIVE_YEARS);

        // Calculate actual price from VRGDA.
        try pages.getPrice(timeSinceStart, numSold) returns (uint256 actualPrice) {
            // Calculate expected price from python script.
            uint256 expectedPrice = calculatePrice(
                timeSinceStart,
                numSold,
                INITIAL_PRICE,
                PER_PERIOD_PRICE_DECREASE,
                LOGISTIC_SCALE,
                TIME_SCALE,
                TIME_SHIFT,
                PER_PERIOD_POST_SWITCHOVER,
                SWITCHOVER_TIME
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
        int256 _PER_PERIOD_PRICE_DECREASE,
        int256 _logisticScale,
        int256 _timeScale,
        int256 _timeShift,
        int256 _perPeriodPostSwitchover,
        int256 _switchoverTime
    ) private returns (uint256) {
        string[] memory inputs = new string[](21);
        inputs[0] = "python3";
        inputs[1] = "analysis/compute_price.py";
        inputs[2] = "pages";
        inputs[3] = "--time_since_start";
        inputs[4] = _timeSinceStart.toString();
        inputs[5] = "--num_sold";
        inputs[6] = _numSold.toString();
        inputs[7] = "--initial_price";
        inputs[8] = uint256(_initialPrice).toString();
        inputs[9] = "--per_period_price_decrease";
        inputs[10] = uint256(_PER_PERIOD_PRICE_DECREASE).toString();
        inputs[11] = "--logistic_scale";
        inputs[12] = uint256(_logisticScale).toString();
        inputs[13] = "--time_scale";
        inputs[14] = uint256(_timeScale).toString();
        inputs[15] = "--time_shift";
        inputs[16] = uint256(_timeShift).toString();
        inputs[17] = "--per_period_post_switchover";
        inputs[18] = uint256(_perPeriodPostSwitchover).toString();
        inputs[19] = "--switchover_time";
        inputs[20] = uint256(_switchoverTime).toString();

        return abi.decode(vm.ffi(inputs), (uint256));
    }
}
