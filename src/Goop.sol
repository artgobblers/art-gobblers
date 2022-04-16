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

    address public pages;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /// @notice Set addresses with authority to mint and burn.
    constructor(address _artGobblers) {
        artGobblers = _artGobblers;
    }

    /*//////////////////////////////////////////////////////////////
                           CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /// @notice Set pages address, callable only by gobblers contract.
    function setPages(address _pages) public only(artGobblers) {
        pages = _pages;
    }

    /*//////////////////////////////////////////////////////////////
                             MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) public only(artGobblers) {
        _mint(to, amount);
    }

    function burnForGobblers(address from, uint256 amount) public only(artGobblers) {
        _burn(from, amount);
    }

    // TODO: we could just transferFrom dont need special burn auth?
    function burnForPages(address from, uint256 amount) public only(pages) {
        _burn(from, amount);
    }
}
