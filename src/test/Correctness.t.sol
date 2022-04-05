// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockVRGDA} from "./utils/mocks/MockVRGDA.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {console} from "./utils/Console.sol";

contract CorrectnessTest is DSTest {
    using Strings for uint256;
    using PRBMathSD59x18 for int256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 internal constant MAX_GOOP_MINT = 7990;

    int256 internal immutable initialPrice = PRBMathSD59x18.fromInt(69);

    int256 internal immutable logisticScale = PRBMathSD59x18.fromInt(int256((MAX_GOOP_MINT + 1) * 2));

    int256 internal immutable timeScale = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(60));

    int256 internal immutable periodPriceDecrease = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(4));

    int256 internal immutable timeShift = 0;

    //test correctness of pricing function for different combinations of time and quantity sold.
    //we match all other parameters (initialPrice, timescale, etc...) to the ones used for
    //gobbler pricing specifically.
    function testCorrectness() public {
        uint256[3] memory timeSinceStart = [uint256(1000), uint256(100000), uint256(50000)];
        uint256[3] memory numSold = [uint256(0), uint256(300), uint256(900)];
        for (uint256 i = 0; i < 3; i++) {
            checkPriceWithParameters(
                timeSinceStart[i],
                numSold[i],
                initialPrice,
                periodPriceDecrease,
                logisticScale,
                timeScale,
                timeShift
            );
        }
    }

    function testFFICorrectnessOne() public {
        checkPriceWithParameters(1000, 0, initialPrice, periodPriceDecrease, logisticScale, timeScale, timeShift);
    }

    function checkPriceWithParameters(
        uint256 _timeSinceStart,
        uint256 _numSold,
        int256 _initialPrice,
        int256 _perPeriodPriceDecrease,
        int256 _logisticScale,
        int256 _timeScale,
        int256 _timeShift
    ) private {
        MockVRGDA vrgda = new MockVRGDA(_logisticScale, _timeScale, _timeShift, _initialPrice, _perPeriodPriceDecrease);

        //calculate actual price from gda
        uint256 actualPrice = vrgda.getPrice(_timeSinceStart, _numSold);
        console.log(actualPrice);
        //calculate expected price from python script
        uint256 expectedPrice = calculatePrice(
            _timeSinceStart,
            _numSold,
            _initialPrice,
            _perPeriodPriceDecrease,
            _logisticScale,
            _timeScale,
            _timeShift
        );
        console.log(expectedPrice);

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
        int256 _timeShift
    ) private returns (uint256) {
        string[] memory inputs = new string[](17);
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
        inputs[15] = "--time_shift";
        inputs[16] = uint256(_timeShift).toString();
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
