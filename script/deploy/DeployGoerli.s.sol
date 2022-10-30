// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployBase} from "./DeployBase.s.sol";

contract DeployGoerli is DeployBase {
     address public immutable coldWallet = 0xE974159205528502237758439da8c4dcc03D3023;
    address public immutable communityWallet = 0xDf2aAeead21Cf2BFF3965E858332aC8c8364E991;
    address public immutable governorWallet = 0x2719E6FdDd9E33c077866dAc6bcdC40eB54cD4f7;

    bytes32 public immutable root = 0xae49de097f1b61ff3ff428b660ddf98b6a8f64ed0f9b665709b13d3721b79405;

    // Fri Oct 28 2022 12:38:52 GMT+0000
    uint256 public immutable mintStart = 1667251200;

    string public constant gobblerBaseUri = "https://nfts.artgobblers.com/api/gobblers/";
    string public constant gobblerUnrevealedUri = "https://nfts.artgobblers.com/api/gobblers/unrevealed";
    string public constant pagesBaseUri = "https://nfts.artgobblers.com/api/pages/";

    bytes32 public immutable provenance = 0x628f3ac523165f5cf33334938a6211f0065ce6dc20a095d5274c34df8504d6e4;

    constructor()
        DeployBase(
            // Governor wallet:
            governorWallet,
            // Team cold wallet:
            coldWallet,
            // Community wallet:
            communityWallet,
            // Merkle root:
            root,
            // Mint start:
            mintStart,
            // VRF coordinator:
            address(0x2bce784e69d2Ff36c71edcB9F88358dB0DfB55b4),
            // LINK token:
            address(0x326C977E6efc84E512bB9C30f76E30c160eD06FB),
            // Chainlink hash:
            0x0476f9a745b61ea5c0ab224d3a6e4c99f0b02fce4da01143a4f70aa80ae76e8a,
            // Chainlink fee:
            0.1e18,
            // Gobbler base URI:
            gobblerBaseUri,
            // Gobbler unrevealed URI:
            gobblerUnrevealedUri,
            // Pages base URI:
            pagesBaseUri,
            // Provenance hash:
            provenance
        )
    {}
}
