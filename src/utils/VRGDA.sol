// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, unsafeWadDiv} from "./SignedWadMath.sol";

/// @title Variable Rate Gradual Dutch Auction
/// @notice Sell NFTs roughly according to an issuance schedule.
/// @dev More details: https://github.com/transmissions11/VRGDAs
abstract contract VRGDA {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Scaling constant to change units between days and seconds.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant DAYS_WAD = 1 days * 1e18;

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

    /// @notice Calculate the price of an NFT according to the VRGDA algorithm.
    /// @param timeSinceStart The time since the initial sale, in seconds.
    /// @param id The token id to get the price of at the current time.
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
                                    getTargetSaleDay(int256(id * 1e18))
                            )
                        )
                    )
                );
        }
    }

    // TODO: idt we should use idWad or describe it as "for a given token id" when its actually for the num sold (which is 1 less than the id)
    /// @dev Get the target sale day (relative to the starting time) for a given token id.
    /// @param idWad The id of the token to get the target sale day for, scaled by 1e18.
    /// @return The target day (relative) to sell the given token id on, scaled by 1e18.
    function getTargetSaleDay(int256 idWad) internal view virtual returns (int256);
}
