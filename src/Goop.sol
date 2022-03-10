// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

///@notice Goop is an in-game token for ArtGobblers. It's a standard ERC20
///@notice that can be burned and minted by the gobblers and pages contract
contract Goop is ERC20("Goop", "GOOP", 18) {
    address public immutable artGobblers;
    address public pages;

    error Unauthorized();

    ///@notice requires sender address to match user address
    modifier only(address user) {
        if (msg.sender != user) {
            revert Unauthorized();
        }
        _;
    }

    ///@notice set addresses with authority to mint and burn
    constructor(address _artGobblers) {
        artGobblers = _artGobblers;
    }

    ///@notice set pages address, callable only by gobblers contract
    function setPages(address _pages) public only(artGobblers) {
        pages = _pages;
    }

    function mint(address to, uint256 value) public only(artGobblers) {
        _mint(to, value);
    }

    function burnForGobblers(address from, uint256 value)
        public
        only(artGobblers)
    {
        _burn(from, value);
    }

    function burnForPages(address from, uint256 value) public only(pages) {
        _burn(from, value);
    }
}
