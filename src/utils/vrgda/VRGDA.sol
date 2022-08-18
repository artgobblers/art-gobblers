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
        targetPrice = _targetPrice;

        decayConstant = wadLn(1e18 - _priceDecreasePercent);

        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of the next token according to the VRGDA formula.
    /// @param timeSinceStart The time since auctions began, in seconds.
    /// @param sold The number of tokens that have been sold so far.
    function getPrice(uint256 timeSinceStart, uint256 sold) public view returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // Theoretically calling toWadUnsafe with timeSinceStart/sold can overflow without
                // detection, but under any reasonable circumstance they will never be large enough.
                // Use ++sold as ASTRO's n param represents the nth token, whereas sold is the n-1th token.
                (toWadUnsafe(timeSinceStart) / 1 days) - getTargetSaleDay(toWadUnsafe(++sold))
            ))));
        }
    }

    /// @dev Given a number of tokens sold, return the target day that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale day for.
    /// @return The target day the tokens should be sold by, scaled by 1e18, where the day is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleDay(int256 sold) public view virtual returns (int256);
}
