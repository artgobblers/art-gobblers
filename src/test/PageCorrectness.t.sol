// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {PagePricer} from "../PagePricer.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {console} from "./utils/Console.sol";

contract PageCorrectnessTest is DSTest {
    using Strings for uint256;
    using PRBMathSD59x18 for int256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 internal immutable FIVE_YEARS = 52 weeks * 5;

    //fuzz purchases up to 10,000 at t = 0
    function testPageCorrectnessStart(uint256 numSold) public {
        //limit num sold to 10,000 to avoid overflows in solidity
        vm.assume(numSold < 10000);
        checkPagePriceWithParameters(0, numSold);
    }

    //fuzz purchases a year after initial mint
    function testPageCorrectnessAfterYear(uint256 numSold) public {
        //if after a year, we've sold less than 7000 pages, price is 0
        //if we've sold more than ~11,000, price will and revert (which is expected)
        vm.assume(numSold > 7000 && numSold < 11000);
        checkPagePriceWithParameters(52 weeks, numSold);
    }

    function testPageCorrectnessSimple() public {
        checkPagePriceWithParameters(52 weeks, 8000);
    }
    
    function checkPagePriceWithParameters(uint256 _timeSinceStart, uint256 _numSold) private {
        // MockVRGDA vrgda = new MockVRGDA(_logisticScale, _timeScale, _timeShift, _initialPrice, _perPeriodPriceDecrease);
        PagePricer pricer = new PagePricer();
        //calculate actual price from gda
        uint256 actualPrice = pricer.pagePrice(_timeSinceStart, _numSold);
        console.log("actual price", actualPrice);
        //calculate expected price from python script
        uint256 expectedPrice = calculatePrice(
            _timeSinceStart,
            _numSold,
            pricer.initialPrice(),
            pricer.periodPriceDecrease(),
            pricer.logisticScale(),
            pricer.timeScale(),
            pricer.timeShift(),
            pricer.perPeriodPostSwitchover(),
            pricer.switchoverTime()
        );
        console.log("expected price", expectedPrice);
        //equal within 0.5 percent
        assertApproxEqual(actualPrice, expectedPrice, 50);
    }

    function calculatePrice(
        uint256 _timeSinceStart,
        uint256 _numSold,
        int256 _initialPrice,
        int256 _perPeriodPriceDecrease,
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
        inputs[10] = uint256(_perPeriodPriceDecrease).toString();
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
        bytes memory res = vm.ffi(inputs);
        uint256 price = abi.decode(res, (uint256));
        return price;
    }

    function assertApproxEqual(
        uint256 expected,
        uint256 actual,
        uint256 tolerance
    ) public {
        uint256 leftBound = (expected * (1000 - tolerance)) / 1000;
        uint256 rightBound = (expected * (1000 + tolerance)) / 1000;
        assertTrue(leftBound <= actual && actual <= rightBound);
    }
}
