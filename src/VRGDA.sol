pragma solidity >=0.8.0;

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

///@notice Variable Rate Gradual Dutch Auction 
contract VRGDA {
    using PRBMathSD59x18 for int256;

    int256 private immutable priceScale;

    int256 private immutable timeScale;

    int256 private immutable initialPrice;

    int256 private immutable periodPriceDecrease;

    int256 private immutable dayScaling = PRBMathSD59x18.fromInt(1 days);

    constructor(
        int256 _priceScale,
        int256 _timeScale,
        int256 _initialPrice,
        int256 _periodPriceDecrease
    ) {
        priceScale = _priceScale;
        timeScale = _timeScale;
        initialPrice = _initialPrice;
        periodPriceDecrease = _periodPriceDecrease;
    }

    
}
