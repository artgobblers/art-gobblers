// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title Variable Rate Gradual Dutch Auction
/// @notice The goal of this mechanism is to sell NFTs roughly according to an issuance schedule.
/// @dev In this case, the issuance schedule is a logistic curve. The pricing function compares
/// the total number of NFTs sold vs the ideal number of sales based on the issuance schedule,
/// and prices new NFTs accordingly. If we are behind schedule, price should go down. If we
/// are ahead of schedule, prices should go down.
contract VRGDA {
    using PRBMathSD59x18 for int256;
    using FixedPointMathLib for uint256;

    /// @notice Initial price of NFTs, to be scaled according to sales rate.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable initialPrice;

    /// @notice This parameter controls the logistic curve's maximum
    /// value, which controls the maximum number of NFTs to be issued.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable logisticScale;

    /// @notice Time scale controls the steepness of the logistic curve, which
    /// effects the time period by which we want to reach the asymptote of the curve.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable timeScale;

    /// @notice Controls the time in which we reach the sigmoid's midpoint.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable timeShift;

    /// @notice controls how quickly price reacts to deviations from issuance schedule.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 private immutable periodPriceDecrease;

    /// @notice scaling constant to change units between days and seconds.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable dayScaling = PRBMathSD59x18.fromInt(1 days);

    /// @notice The initial value the VRGDA logistic pricing formula would output.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable initialValue;

    /// @notice Precomputed constant that allows us to rewrite a .pow() as a .exp().
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable decayConstant;

    /// @notice Precompute 1 expressed scaled as a PRBMathSD59x18 number.
    int256 internal immutable one59x18 = int256(1).fromInt();

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

        // TODO: use the new formula logistic to compute dis
        //
        initialValue =
            logisticScale.mul(
                one59x18 -
                    (timeScale.mul(timeShift)).div(
                        PRBMathSD59x18.sqrt(
                            4e18 +
                                //
                                (timeScale.mul(timeScale)).mul(timeShift.mul(timeShift))
                        )
                    )
            ) /
            2;

        decayConstant = -(one59x18 - periodPriceDecrease).ln();
    }

    /// @notice Calculate the price of an according to VRGDA algorithm.
    /// @param timeSinceStart The time since the initial sale, in seconds.
    /// @param id The token id to get the price of at the current time.
    function getPrice(uint256 timeSinceStart, uint256 id) public view returns (uint256) {
        unchecked {
            int256 idWad = int256(id * 1e18);
            int256 timeSinceStartWad = int256(timeSinceStart * 1e18);

            int256 logisticValue = idWad + initialValue;

            // See: https://www.wolframcloud.com/env/t11s/Published/gobbler-pricing
            int256 exponent = decayConstant.mul(
                // We convert seconds to days here to prevent overflow.
                wadDiv(timeSinceStartWad, dayScaling) +
                    wadDiv(
                        logisticScale - (logisticValue << 1),
                        wadMul(timeScale, wadSqrt(wadMul(logisticScale - initialValue - idWad, logisticValue)))
                    ) -
                    timeShift
            );

            return uint256(wadMul(initialPrice, exponent.exp()));
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO: are these more expensive if they're in a lib?

    function wadSqrt(int256 x) internal pure returns (int256 z) {
        assembly {
            // Scale x by 1e18 to keep the result accurate.
            // TODO: do we need overflow checks here?
            x := mul(x, 1000000000000000000)

            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    function wadMul(int256 x, int256 y) internal pure returns (int256 z) {
        assembly {
            // TODO: do we need overflow checks here?
            z := sdiv(mul(x, y), 1000000000000000000)
        }
    }

    /// @dev Note: Will return 0 instead of reverting if y is zero.
    /// TODO: do we need to use SDIV?
    function wadDiv(int256 x, int256 y) internal pure returns (int256 z) {
        assembly {
            // TODO: do we need overflow checks here?

            z := sdiv(mul(x, 1000000000000000000), y)
        }
    }
}
