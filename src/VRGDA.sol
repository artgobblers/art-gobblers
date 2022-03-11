pragma solidity >=0.8.0;

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

///@notice Variable Rate Gradual Dutch Auction
///The goal of this mechanism is to sell NFTs roughly according to an issuance schedule.
///In this case, the issuance schedule is a logistic curve. The pricing function compares
///the total number of NFTs sold vs the ideal number of sales based on the issuance schedule,
///and prices new NFTs accordingly. If we are behind schedule, price should go down. If we
///are ahead of schedule, prices should go down
contract VRGDA {
    using PRBMathSD59x18 for int256;

    ///@notice parameter controls the logistic curve's maximum value, which
    ///controls the maximum number of NFTs to be issues
    ///@dev represented as a PRBMathSD59x18 number
    int256 private immutable logisticScale;

    ///@notice time scale controls the steepness of the logistic curve, which affects
    ///the time period by which we want to reach the asymptote of the curve
    ///@dev represented as a PRBMathSD59x18 number
    int256 private immutable timeScale;

    ///@notice controls the time in which we reach the sigmoid's midpoint
    ///@dev represented as a PRBMathSD59x18 number
    int256 private immutable timeShift;

    ///@notice Initial price of NFTs, to be scaled according to sales rate
    ///@dev represented as a PRBMathSD59x18 number
    int256 private immutable initialPrice;

    ///@notice controls how quickly price reacts to deviations from issuance schedule
    ///@dev represented as a PRBMathSD59x18 number
    int256 private immutable periodPriceDecrease;

    ///@notice scaling constant to change units between days and seconds
    ///@dev represented as a PRBMathSD59x18 number
    int256 internal immutable dayScaling = PRBMathSD59x18.fromInt(1 days);

    /// @notice The initial value the VRDGA logistic pricing formula would output.
    int256 internal immutable initialValue;

    constructor(
        int256 _logisticScale,
        int256 _timeScale,
        int256 _timeShift,
        int256 _initialPrice,
        int256 _periodPriceDecrease
    ) {
        logisticScale = _logisticScale;
        timeScale = _timeScale;
        timeShift = _timeShift;
        initialPrice = _initialPrice;
        periodPriceDecrease = _periodPriceDecrease;

        initialValue = logisticScale.div(PRBMathSD59x18.fromInt(1) + timeScale.mul(timeShift).exp());
    }

    ///@notice calculate the price according to VRGDA algorithm
    ///@param timeSinceStart The time since the initial sale, in seconds
    ///@param numSold cummulative sales number up until this point
    function getPrice(uint256 timeSinceStart, uint256 numSold) public view returns (uint256) {
        //The following computations are derived from the VRGDA formula
        //using the logistic pricing function.
        //TODO: link to white paper explaining algebraic manipulation

        int256 logisticValue = PRBMathSD59x18.fromInt(int256(numSold + 1)) + initialValue;

        int256 numPeriods = PRBMathSD59x18.fromInt(int256(timeSinceStart)).div(dayScaling) -
            timeShift +
            ((logisticScale.div(logisticValue) - PRBMathSD59x18.fromInt(1)).ln().div(timeScale));

        //The scaling factor is computed by exponentiating the per period scale
        //by the number of periods
        int256 scalingFactor = (PRBMathSD59x18.fromInt(1) - periodPriceDecrease).pow(numPeriods);

        //Multiply the initial price by the scaling factor, and convert back to int
        int256 price = initialPrice.mul(scalingFactor);

        return uint256(price);
    }
}
