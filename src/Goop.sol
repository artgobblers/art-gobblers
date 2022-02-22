// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

///@notice Goop is an in-game token for ArtGobblers. It's a standard ERC20 
///@notice that can be burned and minted by the gobblers and pages contract 
contract Goop is ERC20("Goop", "GOOP", 18) {

    address public artGobblers;
    address public pages;

    error InsufficientBalance();

    error Unauthorized();


    ///@notice requires sender to be either gobblers or pages contract 
    modifier requiresAuth() {
        if (msg.sender != artGobblers && msg.sender != pages) {
            revert Unauthorized();
        }
        _;
    }

    ///@notice set addresses with authority to mint and burn
    constructor(address _artGobblers) {
        artGobblers = _artGobblers;
    }

    ///@notice set pages address, calables only by gobblers contract
    function setPages(address _pages) public requiresAuth { 
        pages = _pages;
    }

    function mint(address to, uint256 value) public requiresAuth {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public requiresAuth {
        if(balanceOf[from] < value) {
            revert InsufficientBalance();
        }
        _burn(from, value);
    }
}
