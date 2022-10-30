// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployBase} from "./DeployBase.s.sol";

contract DeployMainnet is DeployBase {
    address public immutable coldWallet = 0xE974159205528502237758439da8c4dcc03D3023;
    address public immutable communityWallet = 0xDf2aAeead21Cf2BFF3965E858332aC8c8364E991;
    address public immutable governorWallet = 0x2719E6FdDd9E33c077866dAc6bcdC40eB54cD4f7;

    bytes32 public immutable root = 0xae49de097f1b61ff3ff428b660ddf98b6a8f64ed0f9b665709b13d3721b79405;

    // Monday, October 31, 2022 8:20:00 PM
    uint256 public immutable mintStart = 1667247600;

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
            address(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952),
            // LINK token:
            address(0x514910771AF9Ca656af840dff83E8264EcF986CA),
            // Chainlink hash:
            0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445,
            // Chainlink fee:
            2e18,
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
