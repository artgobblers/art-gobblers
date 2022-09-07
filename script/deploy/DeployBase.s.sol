// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Script.sol";

import {LibRLP} from "../../test/utils/LibRLP.sol";

import {GobblerReserve} from "../../src/utils/GobblerReserve.sol";
import {RandProvider} from "../../src/utils/rand/RandProvider.sol";
import {ChainlinkV1RandProvider} from "../../src/utils/rand/ChainlinkV1RandProvider.sol";

import {Goo} from "../../src/Goo.sol";
import {Pages} from "../../src/Pages.sol";
import {ArtGobblers} from "../../src/ArtGobblers.sol";

abstract contract DeployBase is Script {
    // Environment specific variables.
    address private immutable teamColdWallet;
    bytes32 private immutable merkleRoot;
    uint256 private immutable mintStart;
    address private immutable vrfCoordinator;
    address private immutable linkToken;
    bytes32 private immutable chainlinkKeyHash;
    uint256 private immutable chainlinkFee;
    string private gobblerBaseUri;
    string private gobblerUnrevealedUri;
    string private pagesBaseUri;

    // Deploy addresses.
    GobblerReserve public teamReserve;
    GobblerReserve public communityReserve;
    Goo public goo;
    RandProvider public randProvider;
    ArtGobblers public artGobblers;
    Pages public pages;

    constructor(
        address _teamColdWallet,
        bytes32 _merkleRoot,
        uint256 _mintStart,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        string memory _gobblerBaseUri,
        string memory _gobblerUnrevealedUri,
        string memory _pagesBaseUri
    ) {
        teamColdWallet = _teamColdWallet;
        merkleRoot = _merkleRoot;
        mintStart = _mintStart;
        vrfCoordinator = _vrfCoordinator;
        linkToken = _linkToken;
        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;
        gobblerBaseUri = _gobblerBaseUri;
        gobblerUnrevealedUri = _gobblerUnrevealedUri;
        pagesBaseUri = _pagesBaseUri;
    }

    function run() external {
        vm.startBroadcast();

        // Precomputed contract addresses, based on contract deploy nonces.
        // tx.origin is the address who will actually broadcast the contract creations below.
        address gobblerAddress = LibRLP.computeAddress(tx.origin, vm.getNonce(tx.origin) + 4);
        address pageAddress = LibRLP.computeAddress(tx.origin, vm.getNonce(tx.origin) + 5);

        // Deploy team and community reserves, owned by cold wallet.
        teamReserve = new GobblerReserve(ArtGobblers(gobblerAddress), teamColdWallet);
        communityReserve = new GobblerReserve(ArtGobblers(gobblerAddress), teamColdWallet);
        randProvider = new ChainlinkV1RandProvider(
            ArtGobblers(gobblerAddress),
            vrfCoordinator,
            linkToken,
            chainlinkKeyHash,
            chainlinkFee
        );

        // Deploy goo contract.
        goo = new Goo(
            // Gobblers contract address:
            gobblerAddress,
            // Pages contract address:
            pageAddress
        );

        // Deploy gobblers contract,
        artGobblers = new ArtGobblers(
            merkleRoot,
            mintStart,
            goo,
            Pages(pageAddress),
            address(teamReserve),
            address(communityReserve),
            randProvider,
            gobblerBaseUri,
            gobblerUnrevealedUri
        );

        // Deploy pages contract.
        pages = new Pages(mintStart, goo, teamColdWallet, artGobblers, pagesBaseUri);

        vm.stopBroadcast();
    }
}
