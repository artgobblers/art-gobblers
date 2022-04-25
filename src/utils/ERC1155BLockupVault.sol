// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import {GobblersERC1155B} from "./GobblersERC1155B.sol"; // TODO: use generic ERC1155B once in solmate

/// @title ERC1155BLockupVault
/// @notice Locks up ERC1155B tokens until a certain timestamp.
contract ERC1155BLockupVault is ERC1155TokenReceiver {
    /*//////////////////////////////////////////////////////////////
                              CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The owner of the vault, the only user authorized to withdraw gobblers.
    address public immutable OWNER;

    /// @notice The timestamp after which gobblers held in the contract can be claimed.
    uint256 public immutable UNLOCK_TIMESTAMP;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    constructor(address owner, uint256 unlockDelay) {
        OWNER = owner;

        UNLOCK_TIMESTAMP = block.timestamp + unlockDelay;
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw ERC1155B tokens from the vault.
    /// @param token The ERC1155B with tokens to transfer.
    /// @param recipient The address to transfer the tokens to.
    /// @param ids The ids of the tokens to transfer.
    /// @param amounts The amounts of tokens to transfer.
    function withdraw(
        GobblersERC1155B token,
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public {
        // The user calling must be the owner.
        if (msg.sender != OWNER) revert Unauthorized();

        // The unlock timestamp must be in the past.
        if (block.timestamp < UNLOCK_TIMESTAMP) revert Unauthorized();

        // TODO: use special erc1155b funct that doesnt take amounts
        token.safeBatchTransferFrom(address(this), recipient, ids, amounts, "");
    }
}
