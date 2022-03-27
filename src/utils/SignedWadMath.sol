// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

function wadMul(int256 x, int256 y) pure returns (int256 z) {
    assembly {
        // Store x * y in z for now.
        z := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(z, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        z := sdiv(z, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 z) {
    // TODO: why dont we need sdiv???

    assembly {
        // Store x * y in z for now.
        z := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && (x == 0 || (x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), or(iszero(x), eq(sdiv(z, 1000000000000000000), x)))) {
            revert(0, 0)
        }

        // Divide z by y.
        z := sdiv(z, y)
    }
}

/// @dev NOT OVERFLOW SAFE! ONLY USE WHERE OVERFLOW IS NOT POSSIBLE!
function unsafeWadMul(int256 x, int256 y) pure returns (int256 z) {
    // TODO: why dont we need sdiv???

    assembly {
        // Multiply x by y and divide by 1e18.
        z := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Note: Will return 0 instead of reverting if y is zero.
/// @dev NOT OVERFLOW SAFE! ONLY USE WHERE OVERFLOW IS NOT POSSIBLE!
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 z) {
    assembly {
        // Multiply x by 1e18 and divide it by y.
        z := sdiv(mul(x, 1000000000000000000), y)
    }
}

// TODO: update this, just a draft of remco exp
function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it
        // as an int256. This happens when x >= floor(log((2**255 -1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers of two
        // such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904632057985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        assembly {
            // Div in assembly because solidity adds a zero check despite the `unchecked`.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // - the scale factor s = ~6.031367120.
        // - the 2**k factor from the range reduction.
        // - the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 a) pure returns (int256 ret) {
    unchecked {
        // The real natural logarithm is not defined for negative numbers or zero.
        // TODO: did i do this conversion to <= from < properly? should i have added or subtracted one lol

        bool ln36;

        assembly {
            ln36 := and(gt(a, 90000000000000000), lt(a, 1100000000000000000))
        }

        if (ln36) {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            a *= 1e18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.

            int256 z;
            assembly {
                z := sdiv(
                    mul(sub(a, 1000000000000000000000000000000000000), 1000000000000000000000000000000000000),
                    add(a, 1000000000000000000000000000000000000)
                )
            }

            int256 z_squared;
            assembly {
                z_squared := sdiv(mul(z, z), 1000000000000000000000000000000000000)
            }

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            assembly {
                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 3))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 5))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 7))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 9))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 11))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 13))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 15))
            }

            // 8 Taylor terms are sufficient for 36 decimal precision.
            assembly {
                ret := sdiv(seriesSum, 500000000000000000)
            }
        } else {
            // TODO: did i transform this from < to <= right?
            if (a <= 999999999999999999) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return -wadLn(1e36 / a);
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;

            assembly {
                if iszero(lt(a, 38877084059945950922200000000000000000000000000000000000000000000000000000)) {
                    a := div(a, 38877084059945950922200000000000000000000000000000000000)
                    sum := add(sum, 128000000000000000000)
                }

                if iszero(lt(a, 6235149080811616882910000000000000000000000000)) {
                    a := div(a, 6235149080811616882910000000)
                    sum := add(sum, 64000000000000000000)
                }
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            assembly {
                if iszero(lt(a, 7896296018268069516100000000000000)) {
                    a := div(mul(a, 100000000000000000000), 7896296018268069516100000000000000)
                    sum := add(sum, 3200000000000000000000)
                }

                if iszero(lt(a, 888611052050787263676000000)) {
                    a := div(mul(a, 100000000000000000000), 888611052050787263676000000)
                    sum := add(sum, 1600000000000000000000)
                }

                if iszero(lt(a, 298095798704172827474000)) {
                    a := div(mul(a, 100000000000000000000), 298095798704172827474000)
                    sum := add(sum, 800000000000000000000)
                }

                if iszero(lt(a, 5459815003314423907810)) {
                    a := div(mul(a, 100000000000000000000), 5459815003314423907810)
                    sum := add(sum, 400000000000000000000)
                }

                if iszero(lt(a, 738905609893065022723)) {
                    a := div(mul(a, 100000000000000000000), 738905609893065022723)
                    sum := add(sum, 200000000000000000000)
                }

                if iszero(lt(a, 271828182845904523536)) {
                    a := div(mul(a, 100000000000000000000), 271828182845904523536)
                    sum := add(sum, 100000000000000000000)
                }

                if iszero(lt(a, 164872127070012814685)) {
                    a := div(mul(a, 100000000000000000000), 164872127070012814685)
                    sum := add(sum, 50000000000000000000)
                }

                if iszero(lt(a, 128402541668774148407)) {
                    a := div(mul(a, 100000000000000000000), 128402541668774148407)
                    sum := add(sum, 25000000000000000000)
                }

                if iszero(lt(a, 113314845306682631683)) {
                    a := div(mul(a, 100000000000000000000), 113314845306682631683)
                    sum := add(sum, 12500000000000000000)
                }

                if iszero(lt(a, 106449445891785942956)) {
                    a := div(mul(a, 100000000000000000000), 106449445891785942956)
                    sum := add(sum, 6250000000000000000)
                }
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z;
            assembly {
                z := div(mul(sub(a, 100000000000000000000), 100000000000000000000), add(a, 100000000000000000000))
            }

            int256 z_squared;
            assembly {
                z_squared := div(mul(z, z), 100000000000000000000)
            }

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2

            assembly {
                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 3))

                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 5))

                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 7))

                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 9))

                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 11))
            }

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)

            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            assembly {
                ret := div(add(sum, seriesSum), 100)
            }
        }
    }
}
