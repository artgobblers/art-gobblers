// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "../lib/SignedWadMath.sol";

/// @title Variable Rate Gradual Dutch Auction
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice Sell tokens roughly according to an issuance schedule.
abstract contract VRGDA {
    /*//////////////////////////////////////////////////////////////
                            VRGDA PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable targetPrice;

    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    /// @notice Sets initial price and per period price decay for VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace.
    /// @param _priceDecreasePercent Percent price decrease per unit of time.
    constructor(int256 _targetPrice, int256 _priceDecreasePercent) {
        // A negative price decrease would result in a positive decayConstant.
        require(_priceDecreasePercent > 0, "INVALID_PRICE_DECREASE");

        targetPrice = _targetPrice; // Set the target price for a token.

        // The check above ensures that this will always be negative.
        decayConstant = wadLn(1e18 - _priceDecreasePercent);
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart The time since auctions began, in seconds.
    /// @param sold The number of tokens that have been sold so far.
    function getPrice(uint256 timeSinceStart, uint256 sold) public view returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // Theoretically calling toWadUnsafe with timeSinceStart and sold can overflow without
                // detection, but under any reasonable circumstance they will never be large enough.
                (toWadUnsafe(timeSinceStart) / 1 days) - getTargetDayForNextSale(toWadUnsafe(sold))
            ))));
        }
    }

    /// @dev Given the number of tokens sold so far, return the target day the next token should be sold by.
    /// @param sold The number of tokens that have been sold so far, where 0 means none, scaled by 1e18.
    /// @return The target day that the next token should be sold by, scaled by 1e18, where the day
    /// is relative, such that 0 means the token should be sold immediately when the VRGDA begins.
    function getTargetDayForNextSale(int256 sold) internal view virtual returns (int256);
}
