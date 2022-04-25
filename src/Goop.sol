// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title Goop Token (GOOP)
/// @notice Goop is an in-game token for ArtGobblers. It's a standard ERC20
/// token that can be burned and minted by the gobblers and pages contract.
contract Goop is ERC20("Goop", "GOOP", 18) {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public immutable artGobblers;

    address public immutable pages;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _artGobblers, address _pages) {
        artGobblers = _artGobblers;

        pages = _pages;
    }

    /*//////////////////////////////////////////////////////////////
                             MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    function mintForGobblers(address to, uint256 amount) public only(artGobblers) {
        _mint(to, amount);
    }

    function burnForGobblers(address from, uint256 amount) public only(artGobblers) {
        _burn(from, amount);
    }

    function burnForPages(address from, uint256 amount) public only(pages) {
        _burn(from, amount);
    }
}
