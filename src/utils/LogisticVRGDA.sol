// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, wadDiv, unsafeWadDiv} from "./SignedWadMath.sol";

/// @title Logistically Paced Variable Rate Gradual Dutch Auction
/// @notice Sell NFTs roughly according to an issuance schedule. In this case, the issuance
/// schedule is a logistic curve. The pricing function compares the total number of NFTs sold
/// to the ideal number of sales based on the issuance schedule, and prices new NFTs accordingly.
/// Prices go up when NFTs are being sold ahead of schedule, and go down when we are behind schedule.
/// @dev More details available in the paper and/or notebook: https://github.com/transmissions11/VRGDAs
contract LogisticVRGDA {
    /// @notice Scaling constant to change units between days and seconds.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant DAYS_WAD = 1 days * 1e18;

    /// @notice Initial price of NFTs, to be scaled according to sales rate.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable initialPrice;

    /// @notice This parameter controls the logistic curve's maximum
    /// value, which controls the maximum number of NFTs to be issued.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable logisticScale;

    /// @notice Time scale controls the steepness of the logistic curve, which
    /// effects the time period by which we want to reach the asymptote of the curve.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable timeScale;

    /// @notice Controls the time in which we reach the sigmoid's midpoint.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable timeShift;

    /// @notice controls how quickly price reacts to deviations from issuance schedule.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 private immutable periodPriceDecrease;

    /// @notice The initial value the VRGDA logistic pricing formula would output.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable initialValue;

    /// @notice Precomputed constant that allows us to rewrite a .pow() as a .exp().
    /// @dev Represented as an 18 decimal fixed point number.
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

        decayConstant = wadLn(1e18 - periodPriceDecrease);

        initialValue = wadDiv(logisticScale, 1e18 + wadExp(wadMul(timeScale, timeShift)));
    }

    /// @notice Calculate the price of an according to VRGDA algorithm.
    /// @param timeSinceStart The time since the initial sale, in seconds.
    /// @param id The token id to get the price of at the current time.
    // TODO: if we use remco exp does it still revert once time goes beyond t = 275/1033 and such?
    // TODO: maybe we cast back to uint asap to get mroe overflow headroom. at least can do after exp
    function getPrice(uint256 timeSinceStart, uint256 id) public view returns (uint256) {
        unchecked {
            return
                uint256(
                    wadMul(
                        initialPrice,
                        wadExp(
                            unsafeWadMul(
                                decayConstant,
                                // Multiplying timeSinceStart by 1e18 can overflow
                                // without detection, but the sun will devour our
                                // solar system before we need to worry about it.
                                unsafeWadDiv(int256(timeSinceStart * 1e18), DAYS_WAD) -
                                    timeShift +
                                    unsafeWadDiv(
                                        wadLn(unsafeWadDiv(logisticScale, int256(id * 1e18) + initialValue) - 1e18),
                                        timeScale
                                    )
                            )
                        )
                    )
                );
        }
    }
}
