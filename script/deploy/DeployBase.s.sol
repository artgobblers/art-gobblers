// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../../src/ArtGobblers.sol";

import {GobblerReserve} from "../../src/utils/GobblerReserve.sol";

import {Goo} from "../../src/Goo.sol";
import {Pages} from "../../src/Pages.sol";
import {ArtGobblers} from "../../src/ArtGobblers.sol";

import {LibRLP} from "../../src/test/utils/LibRLP.sol";

abstract contract DeployBase is Script {
    //environment specific variables
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

    //contract deploy nonces, used for address computation. Contract nonces start at 1.
    uint256 private immutable gobblerNonce = 5;
    uint256 private immutable pagesNonce = 6;

    //deploy addresses
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

        //deploy team and community reserves, owned by cold wallet.
        teamReserve = new GobblerReserve(
            ArtGobblers(LibRLP.computeAddress(address(this), gobblerNonce)),
            teamColdWallet
        );
        communityReserve = new GobblerReserve(
            ArtGobblers(LibRLP.computeAddress(address(this), gobblerNonce)),
            teamColdWallet
        );

        //deploy goo contract
        goo = new Goo(
            // Gobblers contract address
            LibRLP.computeAddress(address(this), gobblerNonce),
            // Pages contract address
            LibRLP.computeAddress(address(this), pagesNonce)
        );

        //deploy gobblers contract
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

        //deploy pages contract
        pages = new Pages(mintStart, address(artGobblers), goo, pagesBaseUri);

        vm.stopBroadcast();
    }
}
