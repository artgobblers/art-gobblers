// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

import {Goop} from "./Goop.sol";

///@notice Pages is an ERC721 that can hold art drawn
contract Pages is
    ERC721("Pages", "PAGE"),
    Auth
{
    using Strings for uint256;

    ///@notice id of last mint
    uint256 internal currentId;

    ///@notice base token URI
    string internal constant BASE_URI = "";

    ///@notice mint cost, in goop
    uint256 public immutable MINT_COST = 100;

    ///@notice mapping from tokenId to isDrawn bool
    mapping(uint256 => bool) public isDrawn;

    Goop internal goop;

    error InsufficientBalance();

    constructor(address _goop, address owner) Auth(owner, Authority(address(0))){
        goop = Goop(_goop);
    }

    ///@notice set whether page is drawn
    function setIsDrawn(uint256 tokenId) public requiresAuth {
        isDrawn[tokenId] = true;
    }

    ///@notice burn goop and mint page
    function mint() public {
        if (goop.balanceOf(msg.sender) < MINT_COST) {
            revert InsufficientBalance();
        }
        goop.burn(msg.sender, MINT_COST);
        currentId++;
        _mint(msg.sender, currentId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (tokenId > currentId) {
            return "";
        }
        return string(abi.encodePacked(BASE_URI, tokenId.toString()));
    }
}
