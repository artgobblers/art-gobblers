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
    address private immutable governorWallet;
    address private immutable teamColdWallet;
    address private immutable communityWallet;
    bytes32 private immutable merkleRoot;
    uint256 private immutable mintStart;
    address private immutable vrfCoordinator;
    address private immutable linkToken;
    bytes32 private immutable chainlinkKeyHash;
    uint256 private immutable chainlinkFee;
    string private gobblerBaseUri;
    string private gobblerUnrevealedUri;
    string private pagesBaseUri;
    bytes32 private immutable provenanceHash;

    // Deploy addresses.
    GobblerReserve public teamReserve;
    GobblerReserve public communityReserve;
    Goo public goo;
    RandProvider public randProvider;
    ArtGobblers public artGobblers;
    Pages public pages;

    constructor(
        address _governorWallet,
        address _teamColdWallet,
        address _communityWallet,
        bytes32 _merkleRoot,
        uint256 _mintStart,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        string memory _gobblerBaseUri,
        string memory _gobblerUnrevealedUri,
        string memory _pagesBaseUri,
        bytes32 _provenanceHash
    ) {
        governorWallet = _governorWallet;
        teamColdWallet = _teamColdWallet;
        communityWallet = _communityWallet;
        merkleRoot = _merkleRoot;
        mintStart = _mintStart;
        vrfCoordinator = _vrfCoordinator;
        linkToken = _linkToken;
        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;
        gobblerBaseUri = _gobblerBaseUri;
        gobblerUnrevealedUri = _gobblerUnrevealedUri;
        pagesBaseUri = _pagesBaseUri;
        provenanceHash = _provenanceHash;
    }

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 gobblerKey = vm.envUint("GOBBLER_PRIVATE_KEY");
        uint256 pagesKey = vm.envUint("PAGES_PRIVATE_KEY");
        uint256 gooKey = vm.envUint("GOO_PRIVATE_KEY");

        address gobblerDeployerAddress = vm.addr(gobblerKey);
        address pagesDeployerAddress = vm.addr(pagesKey);
        address gooDeployerAddress = vm.addr(gooKey);

        // Precomputed contract addresses, based on contract deploy nonces.
        address gobblerAddress = LibRLP.computeAddress(gobblerDeployerAddress, 0);
        address pageAddress = LibRLP.computeAddress(pagesDeployerAddress, 0);

        vm.startBroadcast(deployerKey);

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

        // Fund each of the other deployer addresses.
        payable(gobblerDeployerAddress).transfer(0.25 ether);
        payable(pagesDeployerAddress).transfer(0.25 ether);
        payable(gooDeployerAddress).transfer(0.25 ether);

        vm.stopBroadcast();

        vm.startBroadcast(gooKey);

        // Deploy goo contract.
        goo = new Goo(
            // Gobblers contract address:
            gobblerAddress,
            // Pages contract address:
            pageAddress
        );

        vm.stopBroadcast();

        vm.startBroadcast(gobblerKey);

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
            gobblerUnrevealedUri,
            provenanceHash
        );

        artGobblers.transferOwnership(governorWallet);

        vm.stopBroadcast();

        vm.startBroadcast(pagesKey);

        // Deploy pages contract.
        pages = new Pages(mintStart, goo, communityWallet, artGobblers, pagesBaseUri);

        vm.stopBroadcast();
    }
}
