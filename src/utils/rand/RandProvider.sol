// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Randomness Provider Interface.
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice Generic asynchronous randomness provider interface.
interface RandProvider {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RandomBytesRequested(bytes32 requestId);
    event RandomBytesReturned(bytes32 requestId, uint256 randomness);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Request random bytes from the randomness provider.
    function requestRandomBytes() external returns (bytes32 requestId);
}
