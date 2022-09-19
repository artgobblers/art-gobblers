// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";

import {ArtGobblers} from "../ArtGobblers.sol";

/// @title Gobbler Reserve
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice Reserves gobblers for an owner while keeping any goo produced.
contract GobblerReserve is Owned {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Art Gobblers contract address.
    ArtGobblers public immutable artGobblers;

    /// @notice Sets the addresses of relevant contracts and users.
    /// @param _artGobblers The address of the ArtGobblers contract.
    /// @param _owner The address of the owner of Gobbler Reserve.
    constructor(ArtGobblers _artGobblers, address _owner) Owned(_owner) {
        artGobblers = _artGobblers;
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw gobblers from the reserve.
    /// @param to The address to transfer the gobblers to.
    /// @param ids The ids of the gobblers to transfer.
    function withdraw(address to, uint256[] calldata ids) external onlyOwner {
        // This is quite inefficient, but it's okay because this is not a hot path.
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                artGobblers.transferFrom(address(this), to, ids[i]);
            }
        }
    }
}
