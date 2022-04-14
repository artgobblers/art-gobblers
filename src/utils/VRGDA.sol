// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "./SignedWadMath.sol";

/// @title Variable Rate Gradual Dutch Auction
/// @notice Sell tokens roughly according to an issuance schedule.
abstract contract VRGDA {
    /*//////////////////////////////////////////////////////////////
                            VRGDA PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initial price of NFTs, to be scaled according to sales rate.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable initialPrice;

    /// @notice Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    constructor(int256 _initialPrice, int256 periodPriceDecrease) {
        initialPrice = _initialPrice;

        decayConstant = wadLn(1e18 - periodPriceDecrease);
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of an token according to the VRGDA formula.
    /// @param timeSinceStart The time since the initial sale, in seconds.
    /// @param sold The number of tokens that have been sold so far.
    function getPrice(uint256 timeSinceStart, uint256 sold) public view returns (uint256) {
        unchecked {
            return
                uint256(
                    wadMul(
                        initialPrice,
                        wadExp(
                            unsafeWadMul(
                                decayConstant,
                                // Theoretically calling toWadUnsafe with timeSinceStart and sold can overflow without
                                // detection, but under any reasonable circumstance they will never be large enough.
                                (toWadUnsafe(timeSinceStart) / 1 days) - getTargetSaleDay(toWadUnsafe(sold))
                            )
                        )
                    )
                );
        }
    }

    /// @dev Given a number of tokens, return the target day they should all be sold by.
    /// @param tokens The number of tokens to get the target sale day for, scaled by 1e18.
    /// @return The target day that the tokens should all be sold by, scaled by 1e18, where the
    /// day is relative, such that 0 means the tokens should be sold on the first day of auctions.
    function getTargetSaleDay(int256 tokens) internal view virtual returns (int256);
}
