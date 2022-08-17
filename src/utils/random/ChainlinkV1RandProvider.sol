// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";

import {ArtGobblers} from "../../ArtGobblers.sol";

import {RandProvider} from "./RandProvider.sol";

/// @title Chainlink V1 Randomness Provider.
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice RandProvider wrapper around Chainlink VRF v1.
contract ChainlinkV1RandProvider is RandProvider, VRFConsumerBase {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Art Gobblers contract.
    ArtGobblers public immutable artGobblers;

    /*//////////////////////////////////////////////////////////////
                            VRF CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @dev Public key to generate randomness against.
    bytes32 internal immutable chainlinkKeyHash;

    /// @dev Fee required to fulfill a VRF request.
    uint256 internal immutable chainlinkFee;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotGobblers();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets relevant addresses and VRF parameters.
    /// @param _artGobblers Address of the ArtGobblers contract.
    /// @param _vrfCoordinator Address of the VRF coordinator.
    /// @param _linkToken Address of the LINK token contract.
    /// @param _chainlinkKeyHash Public key to generate randomness against.
    /// @param _chainlinkFee Fee required to fulfill a VRF request.
    constructor(
        ArtGobblers _artGobblers,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        artGobblers = _artGobblers;

        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;
    }

    /// @notice Request random bytes from Chainlink VRF. Can only by called by the ArtGobblers contract.
    function requestRandomBytes() external returns (bytes32 requestId) {
        // The caller must be the ArtGobblers contract, revert otherwise.
        if (msg.sender != address(artGobblers)) revert NotGobblers();

        emit RandomBytesRequested(requestId);

        // Will revert if we don't have enough LINK to afford the request.
        return requestRandomness(chainlinkKeyHash, chainlinkFee);
    }

    /// @dev Handles VRF response by calling back into the ArtGobblers contract.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomBytesReturned(requestId, randomness);

        artGobblers.acceptRandomSeed(requestId, randomness);
    }
}
