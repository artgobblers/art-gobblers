// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {RandProvider} from "./RandProviderInterface.sol";
import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";
import {ArtGobblers} from "../../ArtGobblers.sol";

contract ChainlinkV1RandProvider is RandProvider, VRFConsumerBase {
    bytes32 internal immutable chainlinkKeyHash;

    uint256 internal immutable chainlinkFee;

    ArtGobblers internal immutable artGobblers;

    error Unauthorized();

    /// @notice Requires caller address to be gobblers contract.
    modifier onlyGobblers() {
        if (msg.sender != address(artGobblers)) revert Unauthorized();
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

    function requestRandomBytes() external onlyGobblers returns (bytes32 requestId) {
        emit RandomBytesRequested(requestId);
        // Will revert if we don't have enough LINK to afford the request.
        return requestRandomness(chainlinkKeyHash, chainlinkFee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomBytesReturned(requestId, randomness);
        artGobblers.acceptRandomSeed(requestId, randomness);
    }
}
