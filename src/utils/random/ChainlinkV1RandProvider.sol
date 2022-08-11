// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {RandProvider} from "./RandProviderInterface.sol";
import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";
import {ArtGobblers} from "../../ArtGobblers.sol";

/// @notice RandProvider wrapper around Chainlink VRF V1
contract ChainlinkV1RandProvider is RandProvider, VRFConsumerBase {
    /// @notice Public key to generate randomness against.
    bytes32 internal immutable chainlinkKeyHash;

    /// @notice Fee required to fulfill a VRF request.
    uint256 internal immutable chainlinkFee;

    /// @notice ArtGobblers contract address.
    ArtGobblers internal immutable artGobblers;

    /// @notice Error thrown when a request is sent from a non-gobblers address.
    error NotGobblers();

    /// @notice Requires caller address to be gobblers contract.
    modifier onlyGobblers() {
        if (msg.sender != address(artGobblers)) revert NotGobblers();
        _;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        ArtGobblers _artGobblers
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;
        artGobblers = _artGobblers;
    }

    /// @notice Request random bytes from Chainlink VRF. Can only by called by gobblers contract
    function requestRandomBytes() external onlyGobblers returns (bytes32 requestId) {
        emit RandomBytesRequested(requestId);
        // Will revert if we don't have enough LINK to afford the request.
        return requestRandomness(chainlinkKeyHash, chainlinkFee);
    }

    /// @notice Handle VRF response by calling back to ArtGobblers contract.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomBytesReturned(requestId, randomness);
        artGobblers.acceptRandomSeed(requestId, randomness);
    }
}
