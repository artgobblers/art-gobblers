// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Randomness Provider Interface. Mainly a wrapper around Chainlink VRF so we can upgrade versions.
interface RandProvider {
    event RandomBytesRequested(bytes32 requestId);

    event RandomBytesReturned(bytes32 requestId, uint256 randomness);

    function requestRandomBytes() external returns (bytes32 requestId);
}
