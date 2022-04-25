// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {ArtGobblers} from "./ArtGobblers.sol";

contract LockupVault is ERC1155TokenReceiver {
    uint256 public immutable UNLOCK;

    address public immutable OWNER;

    ArtGobblers internal gobblers;

    error Unauthorized();

    constructor() {
        // Lock for two years.
        UNLOCK = block.timestamp + 730 days;
        // Make deployer the owner.
        OWNER = msg.sender;
    }

    /// @notice Requires caller address to be owner.
    modifier onlyOwner() {
        if (msg.sender != OWNER) revert Unauthorized();
        _;
    }

    /// @notice Set address for gobblers contract
    function setGobblersAddress(address _gobblers) public onlyOwner {
        gobblers = ArtGobblers(_gobblers);
    }

    /// @notice Withdraw gobblers from vault. All goop accumulated will remain in vault's
    /// balance, which is not withdrawable, meaning it will be lost forever.
    /// TODO: Remove amounts after Gobblers ERC1155B is optimized
    function withdraw(
        address withdrawAddress,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public onlyOwner {
        // Require timestamp to be after unlock.
        if (block.timestamp < UNLOCK) revert Unauthorized();
        gobblers.safeBatchTransferFrom(address(this), withdrawAddress, ids, amounts, "");
    }
}
