// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "../../../VRGDA.sol";

contract MockVRGDA is VRGDA {
    constructor(
        int256 _logisticScale,
        int256 _timeScale,
        int256 _timeShift,
        int256 _initialPrice,
        int256 _periodPriceDecrease
    ) VRGDA(_logisticScale, _timeScale, _timeShift, _initialPrice, _periodPriceDecrease) {}
}
