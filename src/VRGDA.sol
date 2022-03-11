// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

/// @title Variable Rate Gradual Dutch Auction
/// @notice The goal of this mechanism is to sell NFTs roughly according to an issuance schedule.
/// @dev In this case, the issuance schedule is a logistic curve. The pricing function compares
/// the total number of NFTs sold vs the ideal number of sales based on the issuance schedule,
/// and prices new NFTs accordingly. If we are behind schedule, price should go down. If we
/// are ahead of schedule, prices should go down.
contract VRGDA {
    using PRBMathSD59x18 for int256;

    /// @notice Precompute 1 expressed scaled as a PRBMathSD59x18 number.
    int256 internal immutable one59x18 = int256(1).fromInt();

    /// @notice Parameter controls the logistic curve's maximum
    /// value, which controls the maximum number of NFTs to be issued.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable logisticScale;

    /// @notice time scale controls the steepness of the logistic curve, which
    /// affects the time period by which we want to reach the asymptote of the curve
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable timeScale;

    /// @notice controls the time in which we reach the sigmoid's midpoint
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable timeShift;

    /// @notice Initial price of NFTs, to be scaled according to sales rate
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable initialPrice;

    /// @notice controls how quickly price reacts to deviations from issuance schedule
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable periodPriceDecrease;

    /// @notice scaling constant to change units between days and seconds
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable dayScaling = PRBMathSD59x18.fromInt(1 days);

    /// @notice The initial value the VRGDA logistic pricing formula would output.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable initialValue;

    /// @notice Precomputed constant that allows us to rewrite a .pow() as a .exp().
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable decayConstant;

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

        initialValue = logisticScale.div(one59x18 + timeScale.mul(timeShift).exp());

        decayConstant = -(one59x18 - periodPriceDecrease).ln();
    }

    /// @notice Calculate the price of an according to VRGDA algorithm.
    /// @param timeSinceStart The time since the initial sale, in seconds.
    /// @param id The token id to get the price of at the current time.
    function getPrice(uint256 timeSinceStart, uint256 id) public view returns (uint256) {
        int256 logisticValue = int256(id).fromInt() + initialValue;

        int256 exponent = decayConstant.mul(
            // We convert seconds to days here to prevent overflow.
            PRBMathSD59x18.fromInt(int256(timeSinceStart)).div(dayScaling) -
                timeShift +
                (logisticScale.div(logisticValue) - one59x18).ln().div(timeScale)
        );

        int256 scalingFactor = exponent.exp(); // This will always be positive.

        return uint256(initialPrice.mul(scalingFactor));
    }
}
