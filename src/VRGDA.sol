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
    int256 internal immutable dayScaling = 1 days * 1e18;

    /// @notice The initial value the VRGDA logistic pricing formula would output.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable initialValue;

    /// @notice Precomputed constant that allows us to rewrite a .pow() as a .exp().
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable decayConstant;

    /// @dev Difference between logisticScale and initialValue.
    /// @dev Represented as a PRBMathSD59x18 number.
    int256 internal immutable initialScaleDelta;

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

        unchecked {
            initialValue =
                logisticScale.mul(
                    1e18 -
                        (timeScale.mul(timeShift)).div(
                            PRBMathSD59x18.sqrt(4e18 + (timeScale.mul(timeScale)).mul(timeShift.mul(timeShift)))
                        )
                ) >>
                1;

            decayConstant = -(1e18 - periodPriceDecrease).ln();

            initialScaleDelta = logisticScale - initialValue;
        }
    }

    /// @notice Calculate the price of an according to VRGDA algorithm.
    /// @param timeSinceStart The time since the initial sale, in seconds.
    /// @param id The token id to get the price of at the current time.
    function getPrice(uint256 timeSinceStart, uint256 id) public view returns (uint256) {
        unchecked {
            int256 idWad = int256(id * 1e18);
            int256 daysSinceStartWad = wadDiv(int256(timeSinceStart * 1e18), dayScaling);

            int256 logisticValue = idWad + initialValue;

            // See: https://www.wolframcloud.com/env/t11s/Published/gobbler-pricing
            int256 exponent = wadMul(
                daysSinceStartWad +
                    wadDiv(
                        logisticScale - (logisticValue << 1), // Left shift is like multiplying by 2.
                        wadMul(timeScale, wadSqrt(wadMul(initialScaleDelta - idWad, logisticValue)))
                    ) -
                    timeShift,
                decayConstant
            );

            return uint256(wadMul(initialPrice, wadExp(exponent)));
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function wadMul(int256 x, int256 y) internal pure returns (int256 z) {
        assembly {
            // TODO: do we need overflow checks here?
            z := sdiv(mul(x, y), 1000000000000000000)
        }
    }

    /// @dev Note: Will return 0 instead of reverting if y is zero.
    function wadDiv(int256 x, int256 y) internal pure returns (int256 z) {
        assembly {
            // TODO: do we need overflow checks here?
            z := sdiv(mul(x, 1000000000000000000), y)
        }
    }

    /// @dev Note: Takes an int256 but assumes it's positive.
    /// @dev Only returns positive numbers, uses int256 for convenience.
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

    function wadExp(int256 x) internal pure returns (int256 z) {
        unchecked {
            // TODO: do we need to check x is less than the max of 130e18 ish
            // TODO: do we need to check x is greater than the min of int min

            if (x < 0) {
                z = wadExp(-x); // Compute exp for x as a positive.

                assembly {
                    // Divide it by 1e36, to get the inverse of the result.
                    z := div(1000000000000000000000000000000000000, z)
                }

                return z; // Beyond this if statement we know x is positive.
            }

            z = 1; // Will multiply the result by this at the end. Default to 1 as a no-op, may be increased below.

            if (x >= 128000000000000000000) {
                x -= 128000000000000000000; // 2ˆ7 scaled by 1e18.

                // Because eˆ12800000000000000000 exp'd is too large to fit in 20 decimals, we'll store it unscaled.
                z = 38877084059945950922200000000000000000000000000000000000; // We'll multiply by this at the end.
            } else if (x >= 64000000000000000000) {
                x -= 64000000000000000000; // 2^6 scaled by 1e18.

                // Because eˆ64000000000000000000 exp'd is too large to fit in 20 decimals, we'll store it unscaled.
                z = 6235149080811616882910000000; // We'll multiply by this at the end, assuming x is large enough.
            }

            x *= 100; // Scale x to 20 decimals for extra precision.

            uint256 precomputed = 1e20; // Will store the product of precomputed powers of 2 (which almost add up to x) exp'd.

            assembly {
                if iszero(lt(x, 3200000000000000000000)) {
                    x := sub(x, 3200000000000000000000) // 2ˆ5 scaled by 1e18.

                    // Multiplied by eˆ3200000000000000000000 scaled by 1e20 and divided by 1e20.
                    precomputed := div(mul(precomputed, 7896296018268069516100000000000000), 100000000000000000000)
                }

                if iszero(lt(x, 1600000000000000000000)) {
                    x := sub(x, 1600000000000000000000) // 2ˆ4 scaled by 1e18.

                    // Multiplied by eˆ16000000000000000000 scaled by 1e20 and divided by 1e20.
                    precomputed := div(mul(precomputed, 888611052050787263676000000), 100000000000000000000)
                }

                if iszero(lt(x, 800000000000000000000)) {
                    x := sub(x, 800000000000000000000) // 2ˆ3 scaled by 1e18.

                    // Multiplied by eˆ8000000000000000000 scaled by 1e20 and divided by 1e20.
                    precomputed := div(mul(precomputed, 2980957987041728274740004), 100000000000000000000)
                }

                if iszero(lt(x, 400000000000000000000)) {
                    x := sub(x, 400000000000000000000) // 2ˆ2 scaled by 1e18.

                    // Multiplied by eˆ4000000000000000000 scaled by 1e20 and divided by 1e20.
                    precomputed := div(mul(precomputed, 5459815003314423907810), 100000000000000000000)
                }

                if iszero(lt(x, 200000000000000000000)) {
                    x := sub(x, 200000000000000000000) // 2ˆ1 scaled by 1e18.

                    // Multiplied by eˆ2000000000000000000 scaled by 1e20 and divided by 1e20.
                    precomputed := div(mul(precomputed, 738905609893065022723), 100000000000000000000)
                }

                if iszero(lt(x, 100000000000000000000)) {
                    x := sub(x, 100000000000000000000) // 2ˆ0 scaled by 1e18.

                    // Multiplied by eˆ1000000000000000000 scaled by 1e20 and divided by 1e20.
                    precomputed := div(mul(precomputed, 271828182845904523536), 100000000000000000000)
                }

                if iszero(lt(x, 50000000000000000000)) {
                    x := sub(x, 50000000000000000000) // 2ˆ-1 scaled by 1e18.

                    // Multiplied by eˆ5000000000000000000 scaled by 1e20 and divided by 1e20.
                    precomputed := div(mul(precomputed, 164872127070012814685), 100000000000000000000)
                }

                if iszero(lt(x, 25000000000000000000)) {
                    x := sub(x, 25000000000000000000) // 2ˆ-2 scaled by 1e18.

                    // Multiplied by eˆ250000000000000000 scaled by 1e20 and divided by 1e20.
                    precomputed := div(mul(precomputed, 128402541668774148407), 100000000000000000000)
                }
            }

            // We'll be using the Taylor series for e^x which looks like: 1 + x + (x^2 / 2!) + ... + (x^n / n!)
            // to approximate the exp of the remaining value x not covered by the precomputed product above.
            uint256 term = uint256(x); // Will track each term in the Taylor series, beginning with x.
            uint256 series = 1e20 + term; // The Taylor series begins with 1 plus the first term, x.

            assembly {
                term := div(mul(term, x), 200000000000000000000) // Equal to dividing x^2 by 2e20 as the first term was just x.
                series := add(series, term)

                term := div(mul(term, x), 300000000000000000000) // Equal to dividing x^3 by 6e20 (3!) as the last term was x divided by 2e20.
                series := add(series, term)

                term := div(mul(term, x), 400000000000000000000) // Equal to dividing x^4 by 24e20 (4!) as the last term was x divided by 6e20.
                series := add(series, term)

                term := div(mul(term, x), 500000000000000000000) // Equal to dividing x^5 by 120e20 (5!) as the last term was x divided by 24e20.
                series := add(series, term)

                term := div(mul(term, x), 600000000000000000000) // Equal to dividing x^6 by 720e20 (6!) as the last term was x divided by 120e20.
                series := add(series, term)

                term := div(mul(term, x), 700000000000000000000) // Equal to dividing x^7 by 5040e20 (7!) as the last term was x divided by 720e20.
                series := add(series, term)

                term := div(mul(term, x), 800000000000000000000) // Equal to dividing x^8 by 40320e20 (8!) as the last term was x divided by 5040e20.
                series := add(series, term)

                term := div(mul(term, x), 900000000000000000000) // Equal to dividing x^9 by 362880e20 (9!) as the last term was x divided by 40320e20.
                series := add(series, term)

                term := div(mul(term, x), 1000000000000000000000) // Equal to dividing x^10 by 3628800e20 (10!) as the last term was x divided by 362880e20.
                series := add(series, term)

                term := div(mul(term, x), 1100000000000000000000) // Equal to dividing x^11 by 39916800e20 (11!) as the last term was x divided by 3628800e20.
                series := add(series, term)

                term := div(mul(term, x), 1200000000000000000000) // Equal to dividing x^12 by 479001600e20 (12!) as the last term was x divided by 39916800e20.
                series := add(series, term)
            }

            // Since e^x * e^y equals e^(x+y) we multiply our Taylor series and precomputed exp'd powers of 2 to get the final result scaled by 1e20.
            return ((int256((series * precomputed) / 1e20)) * z) / 100; // We divide the final result by 100 to scale it back down to 18 decimals of precision.
        }
    }
}
