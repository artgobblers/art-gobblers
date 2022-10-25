// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DeployBase} from "./DeployBase.s.sol";

contract DeployMainnet is DeployBase {
    //TODO: COLD WALLET
    address public immutable coldWallet = address(0xDEADBEA7);
    //TODO: COMMUNITY WALLET
    address public immutable communityWallet = address(0xBEEFBABE);
    //TODO: ROOT
    address public immutable root = address(0xB0BABABE);

    ///Mon Oct 31 2022 21:20:00 GMT+0000
    uint256 public immutable mintStart = 1667251200;

    //TODO: CONSTANTS
    string public constant gobblerBaseUri = "https://testnet.ag.xyz/api/nfts/gobblers/";
    string public constant gobblerUnrevealedUri = "https://testnet.ag.xyz/api/nfts/unrevealed";
    string public constant pagesBaseUri = "https://testnet.ag.xyz/api/nfts/pages/";

    //TODO: PROVENANCE
    address public immutable provenance = address(0xBEEB00);

    constructor()
        DeployBase(
            // Team cold wallet:
            coldWallet,
            // Community wallet:
            communityWallet,
            // Merkle root:
            keccak256(abi.encodePacked(root)),
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
            keccak256(abi.encodePacked(provenance))
        )
    {}
}
