// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

import {Goop} from "./Goop.sol";

///@notice Pages is an ERC721 that can hold art drawn
contract Pages is ERC721("Pages", "PAGE"), Auth {
    using Strings for uint256;
    using PRBMathSD59x18 for int256;

    /// ----------------------------
    /// --------- State ------------
    /// ----------------------------

    ///@notice id of last mint
    uint256 internal currentId;

    ///@notice base token URI
    string internal constant BASE_URI = "";

    ///@notice mapping from tokenId to isDrawn bool
    mapping(uint256 => bool) public isDrawn;

    Goop internal goop;

    /// ----------------------------
    /// ---- Pricing Parameters ----
    /// ----------------------------

    int256 private immutable priceScale = 1;

    int256 private immutable timeScale = 1;

    int256 private immutable timeShift = 1;

    int256 private immutable initialPrice = 1;

    int256 private immutable periodPriceDecrease = 1;

    int256 private immutable perPeriodPostSwitchover = 1;
    
    int256 private immutable switchoverTime = 1;

    uint256 private lastPurchaseTime;

    uint256 private numSold;


    error InsufficientBalance();

    constructor(address _goop, address owner)
        Auth(owner, Authority(address(0)))
    {
        goop = Goop(_goop);
    }

    ///@notice set whether page is drawn
    function setIsDrawn(uint256 tokenId) public requiresAuth {
        isDrawn[tokenId] = true;
    }

    ///@notice burn goop and mint page
    function mint() public {
        uint256 price = pagePrice();
        if (goop.balanceOf(msg.sender) < price) {
            revert InsufficientBalance();
        }
        goop.burn(msg.sender, price);
        _mint(msg.sender, ++currentId);
    }

    function pagePrice() internal view returns (uint256) {
        uint256 threshold = switchThreshold();
        if (threshold < currentId) { 
            return preSwitchPrice();
        }
        else {
            return postSwitchPrice(threshold);
        }
    }

    function switchThreshold() internal view returns (uint256) {
        int256 t = int256(block.timestamp - lastPurchaseTime);
        int256 exp = PRBMathSD59x18.fromInt(-1).mul(timeScale).mul(t - timeShift).exp();
        int256 res = priceScale.div(PRBMathSD59x18.fromInt(1) + exp);
        return uint256(res.toInt());
    }

    function preSwitchPrice() internal view returns (uint256) {
        int256 exp = PRBMathSD59x18.fromInt(
            int256(block.timestamp - lastPurchaseTime)
        ) -
            timeShift +
            (
                (
                    (PRBMathSD59x18.fromInt(-1) + priceScale).div(
                        PRBMathSD59x18.fromInt(int256(numSold))
                    )
                ).ln().div(timeScale)
            );
        int256 scalingFactor = (PRBMathSD59x18.fromInt(1) - periodPriceDecrease)
            .pow(exp);
        int256 price = initialPrice.mul(scalingFactor);
        return uint256(price.toInt());
    }

    function postSwitchPrice(uint256 threshold) internal view returns (uint256) {
        int256 t = int256(block.timestamp - lastPurchaseTime).fromInt();
        int256 delta = int256(currentId - threshold).fromInt();
        int256 fInv = delta.div(perPeriodPostSwitchover) + switchoverTime;
        int256 log = -((PRBMathSD59x18.fromInt(1) - periodPriceDecrease).ln());
        int256 scalingFactor = log.mul(fInv - t).exp();
        int256 price = initialPrice.mul(scalingFactor);
        return uint256(price.toInt());
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
