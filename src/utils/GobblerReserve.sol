// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import {ArtGobblers} from "../ArtGobblers.sol";

/// @title Gobbler Reserve
/// @notice Reserves gobblers for an owner while keeping any goo produced.
contract GobblerReserve is Owned, ERC1155TokenReceiver {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/
    ArtGobblers public artGobblers;

    constructor(ArtGobblers _artGobblers, address _owner) Owned(_owner) {
        artGobblers = _artGobblers;
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw gobblers from the reserve.
    /// @param to The address to transfer the gobblers to.
    /// @param ids The ids of the gobblers to transfer.
    function withdraw(address to, uint256[] calldata ids) public onlyOwner {
        artGobblers.safeBatchTransferFrom(address(this), to, ids, "");
    }
}
