// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DeployBase} from "./DeployBase.s.sol";

contract DeployRinkeby is DeployBase {
    address public immutable coldWallet = 0x126620598A797e6D9d2C280b5dB91b46F27A8330;

    address public immutable root = 0x1D18077167c1177253555e45B4b5448B11E30b4b;

    uint256 public immutable mintStart = 1656369768;

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
            address(0x6168499c0cFfCaCD319c818142124B7A15E857ab),
            // LINK token:
            address(0x01BE23585060835E02B77ef475b0Cc51aA1e0709),
            // Chainlink hash:
            0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc,
            // Chainlink fee:
            0.25e18,
            // Gobbler base URI:
            gobblerBaseUri,
            // Gobbler unrevealed URI:
            gobblerUnrevealedUri,
            // Pages base URI:
            pagesBaseUri
        )
    {}
}
