// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {VRGDA} from "../../../utils/VRGDA.sol";
import {LogisticVRGDA} from "../../../utils/LogisticVRGDA.sol";

contract MockLogisticVRGDA is LogisticVRGDA {
    constructor(
        int256 _initialPrice,
        int256 periodPriceDecrease,
        int256 _logisticScale,
        int256 _timeScale,
        int256 _timeShift
    ) VRGDA(_initialPrice, periodPriceDecrease) LogisticVRGDA(_logisticScale, _timeScale, _timeShift) {}
}
