// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployBase} from "./DeployBase.s.sol";

contract DeployGoerli is DeployBase {
    address public immutable coldWallet = 0x126620598A797e6D9d2C280b5dB91b46F27A8330;

    address public immutable root = 0x1D18077167c1177253555e45B4b5448B11E30b4b;

    ///2022-09-22T01:22:45+00:00
    uint256 public immutable mintStart = 1663809768;

    string public constant gobblerBaseUri = "https://testnet.ag.xyz/api/nfts/gobblers/";
    string public constant gobblerUnrevealedUri = "https://testnet.ag.xyz/api/nfts/unrevealed";
    string public constant pagesBaseUri = "https://testnet.ag.xyz/api/nfts/pages/";

    constructor()
        DeployBase(
            // Team cold wallet:
            coldWallet,
            // Merkle root:
            keccak256(abi.encodePacked(root)),
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
            pagesBaseUri
        )
    {}
}
