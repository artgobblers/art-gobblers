// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "forge-std/Script.sol";

import {LibRLP} from "../../src/test/utils/LibRLP.sol";

import {GobblerReserve} from "../../src/utils/GobblerReserve.sol";

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

    // Precomputed contract addresses, based on contract deploy nonces.
    address private immutable gobblerAddress = LibRLP.computeAddress(address(this), 5);
    address private immutable pageAddress = LibRLP.computeAddress(address(this), 6);

    // Deploy addresses.
    GobblerReserve public teamReserve;
    GobblerReserve public communityReserve;
    Goo public goo;
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

        // Deploy team and community reserves, owned by cold wallet.
        teamReserve = new GobblerReserve(ArtGobblers(gobblerAddress), teamColdWallet);
        communityReserve = new GobblerReserve(ArtGobblers(gobblerAddress), teamColdWallet);

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
            address(teamReserve),
            address(communityReserve),
            vrfCoordinator,
            linkToken,
            chainlinkKeyHash,
            chainlinkFee,
            gobblerBaseUri,
            gobblerUnrevealedUri
        );

        // Deploy pages contract.
        pages = new Pages(mintStart, address(artGobblers), goo, pagesBaseUri);

        vm.stopBroadcast();
    }
}
