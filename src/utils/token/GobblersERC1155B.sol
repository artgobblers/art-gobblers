// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

/// @notice ERC1155B implementation optimized for ArtGobblers by using the ownerOf storage slot to store attribute data.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/v7/src/tokens/ERC1155B.sol)
abstract contract GobblersERC1155B {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                        GOBBLERS/ERC1155B STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding gobbler data.
    struct GobblerData {
        // The current owner of the gobbler.
        address owner;
        // Index of token after shuffle.
        uint64 idx;
        // Multiple on goo issuance.
        uint32 emissionMultiple;
    }

    mapping(uint256 => GobblerData) public getGobblerData;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        return getGobblerData[id].owner;
    }

    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 bal) {
        address idOwner = getGobblerData[id].owner;

        assembly {
            // We avoid branching by using assembly to take
            // the bool output of eq() and use it as a uint.
            bal := eq(idOwner, owner)
        }
    }

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual;

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        getGobblerData[id].owner = to;

        // Does not check if the token was already minted or the recipient is address(0)
        // because ArtGobblers.sol manages its ids in such a way that it ensures it won't
        // double mint and will only mint to safe addresses or msg.sender who cannot be zero.

        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, 1, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        }
    }

    function _batchMint(
        address to,
        uint256 amount,
        uint256 lastMintedId,
        bytes memory data
    ) internal returns (uint256) {
        // Doesn't check if the tokens were already minted or the recipient is address(0)
        // because ArtGobblers.sol manages its ids in such a way that it ensures it won't
        // double mint and will only mint to safe addresses or msg.sender who cannot be zero.

        // Allocate arrays before entering the loop.
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        // Counter overflow is unrealistic on human timescales.
        unchecked {
            for (uint256 i = 0; i < amount; ++i) {
                ids[i] = ++lastMintedId; // Increment id while setting.

                amounts[i] = 1; // ERC1155B amounts are always 1.

                getGobblerData[lastMintedId].owner = to;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        }

        return lastMintedId; // Return the new last minted id.
    }
}
