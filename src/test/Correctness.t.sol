// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockLogisticVRGDA} from "./utils/mocks/MockLogisticVRGDA.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {console} from "./utils/Console.sol";

contract CorrectnessTest is DSTestPlus {
    using Strings for uint256;
    using PRBMathSD59x18 for int256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    uint256 internal constant MAX_GOOP_MINT = 7990;

    int256 internal immutable initialPrice = PRBMathSD59x18.fromInt(69);

    int256 internal immutable logisticScale = PRBMathSD59x18.fromInt(int256((MAX_GOOP_MINT + 1) * 2));

    int256 internal immutable timeScale = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(60));

    int256 internal immutable periodPriceDecrease = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(4));

    uint256 internal immutable FIVE_YEARS = 52 weeks * 5;

    //fuzz test correctness of pricing function for different combinations of time and quantity sold.
    //we match all other parameters (initialPrice, timescale, etc...) to the ones used for
    //gobbler pricing specifically.
    // function testCorrectness(uint256 timeSinceStart, uint256 numSold) public {
    //     //limit num sold to max mint
    //     numSold = bound(numSold, 0, MAX_GOOP_MINT);
    //     //limit mint time to 5 yeras
    //     timeSinceStart = bound(timeSinceStart, 0, FIVE_YEARS);

    //     checkPriceWithParameters(
    //         timeSinceStart,
    //         numSold,
    //         initialPrice,
    //         periodPriceDecrease,
    //         logisticScale,
    //         timeScale
    //     );
    // }

    function checkPriceWithParameters(
        uint256 _timeSinceStart,
        uint256 _numSold,
        int256 _initialPrice,
        int256 perPeriodPriceDecrease,
        int256 _logisticScale,
        int256 _timeScale
    ) private {
        MockLogisticVRGDA vrgda = new MockLogisticVRGDA(
            _initialPrice,
            perPeriodPriceDecrease,
            _logisticScale,
            _timeScale
        );
        //calculate actual price from gda
        uint256 actualPrice = vrgda.getPrice(_timeSinceStart, _numSold);
        //calculate expected price from python script
        uint256 expectedPrice = calculatePrice(
            _timeSinceStart,
            _numSold,
            _initialPrice,
            perPeriodPriceDecrease,
            _logisticScale,
            _timeScale
        );
        if (actualPrice == expectedPrice) return;
        //equal within 1 percent
        assertRelApproxEq(actualPrice, expectedPrice, 1e16);
    }

    function calculatePrice(
        uint256 _timeSinceStart,
        uint256 _numSold,
        int256 _initialPrice,
        int256 perPeriodPriceDecrease,
        int256 _logisticScale,
        int256 _timeScale
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
        inputs[10] = uint256(perPeriodPriceDecrease).toString();
        inputs[11] = "--logistic_scale";
        inputs[12] = uint256(_logisticScale).toString();
        inputs[13] = "--time_scale";
        inputs[14] = uint256(_timeScale).toString();
        inputs[15] = "--time_shift";
        inputs[16] = uint256(0).toString();
        bytes memory res = vm.ffi(inputs);
        uint256 price = abi.decode(res, (uint256));
        return price;
    }
}
