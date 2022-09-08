// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import {ArtGobblers} from "../ArtGobblers.sol";

/// @title Gobbler Reserve
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice Reserves gobblers for an owner while keeping any goo produced.
contract GobblerReserve is Owned, ERC1155TokenReceiver {
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
    /// @param amounts The amounts of each gobbler to transfer (must be 1).
    function withdraw(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        // We could generate amounts in-memory, but getting via calldata is cheaper.
        artGobblers.safeBatchTransferFrom(address(this), to, ids, amounts, "");
    }
}
