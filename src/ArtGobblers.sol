// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";

import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";

import {VRGDA} from "./utils/VRGDA.sol";
import {LogisticVRGDA} from "./utils/LogisticVRGDA.sol";
import {GobblersERC1155B} from "./utils/GobblersERC1155B.sol";

import {Goop} from "./Goop.sol";
import {Pages} from "./Pages.sol";
import {LockupVault} from "./LockupVault.sol";

// TODO: UNCHECKED
// TODO: events

/// @title Art Gobblers NFT (GBLR)
/// @notice Art Gobblers scan the cosmos in search of art producing life.
contract ArtGobblers is GobblersERC1155B, LogisticVRGDA, VRFConsumerBase, ERC1155TokenReceiver {
    using Strings for uint256;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    Goop public immutable goop;

    Pages public immutable pages; // TODO: do we still wanna deploy and maintain from here? we dont interact with pages in this contract at all.

    LockupVault public immutable vault;

    /*//////////////////////////////////////////////////////////////
                            SUPPLY CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable tokens.
    uint256 private constant MAX_SUPPLY = 10000;

    /// @notice Maximum amount of gobblers mintable via whitelist.
    uint256 private constant WHITELIST_SUPPLY = 2000;

    /// @notice Maximum amount of mintable legendary gobblers.
    uint256 private constant LEGENDARY_SUPPLY = 10;

    /*//////////////////////////////////////////////////////////////
                            URI CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Base URI for minted gobblers.
    string public BASE_URI;

    /// @notice URI for gobblers that have yet to be revealed.
    string public UNREVEALED_URI;

    /*//////////////////////////////////////////////////////////////
                              VRF CONSTANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 internal immutable chainlinkKeyHash;

    uint256 internal immutable chainlinkFee;

    /*//////////////////////////////////////////////////////////////
                             WHITELIST STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Merkle root of mint whitelist.
    bytes32 public immutable merkleRoot;

    /// @notice Mapping to keep track of which addresses have claimed from whitelist.
    mapping(address => bool) public claimedWhitelist;

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of the whitelist & VRGDA mint.
    uint256 public immutable mintStart;

    /// @notice Number of gobblers minted from goop.
    uint128 public numMintedFromGoop;

    /*//////////////////////////////////////////////////////////////
                         STANDARD GOBBLER STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Id of last minted non legendary token.
    uint128 internal currentNonLegendaryId; // TODO: public?

    /*//////////////////////////////////////////////////////////////
                         MINT BY AUTHORITY STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of gobblers minted by authority.
    uint128 internal numMintedByAuthority;

    /*///////////////////////////////////////////////////////////////
                    LEGENDARY GOBBLER AUCTION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Last 10 ids are reserved for legendary gobblers.
    uint256 private constant LEGENDARY_GOBBLER_ID_START = MAX_SUPPLY - 10;

    /// @notice Struct holding info required for legendary gobbler auctions.
    struct LegendaryGobblerAuctionData {
        /// @notice Start price of current legendary gobbler auction.
        uint120 currentLegendaryGobblerStartPrice;
        /// @notice Start timestamp of current legendary gobbler auction.
        uint120 currentLegendaryGobblerAuctionStart;
        /// @notice Id of last minted legendary gobbler.
        /// @dev 16 bits has a max value of ~60,000,
        /// which is safely within our limits here.
        uint16 currentLegendaryId; // TODO: current legendary id is kinda confusing cuz the first id isnt actually legendary
    }

    /// @notice Data about the current legendary gobbler auction.
    LegendaryGobblerAuctionData public legendaryGobblerAuctionData;

    /*//////////////////////////////////////////////////////////////
                         ATTRIBUTES REVEAL STATE
    //////////////////////////////////////////////////////////////*/

    // TODO: investigate pack

    /// @notice Random seed obtained from VRF.
    uint256 public randomSeed;

    /// @notice Index of last token that has been revealed.
    uint128 public lastRevealedIndex;

    /// @notice Remaining gobblers to be assigned from seed.
    uint128 public gobblersToBeAssigned;

    /*//////////////////////////////////////////////////////////////
                              STAKING STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding info required for goop staking reward calculations.
    struct StakingData {
        /// @notice The sum of the multiples of all gobblers the user holds.
        uint64 stakingMultiple;
        /// @notice Balance at time of last deposit or withdrawal.
        uint128 lastBalance;
        /// @notice Timestamp of last deposit or withdrawal.
        uint64 lastTimestamp;
    }

    /// @notice Maps user addresses to their staking data.
    mapping(address => StakingData) public getStakingDataForUser;

    /*//////////////////////////////////////////////////////////////
                            ART FEEDING STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from NFT contracts to their ids to gobbler ids they were fed to.
    mapping(address => mapping(uint256 => uint256)) public getGobblerFromFedArt;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Legendary gobbler was minted.
    event LegendaryGobblerMint(uint256 gobblerId);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    error AlreadyEaten();

    error CannotBurnLegendary();

    error InsufficientGobblerBalance();

    error NoRemainingLegendaryGobblers();

    error NoRemainingGobblers();

    constructor(
        bytes32 _merkleRoot,
        uint256 _mintStart,
        address _vault,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        string memory _baseUri
    )
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        VRGDA(
            6.9e18, // Initial price.
            0.31e18 // Per period price decrease.
        )
        LogisticVRGDA(
            // Logistic scale. We multiply by 2x (as a wad)
            // to account for the subtracted initial value,
            // and add 1 to ensure all the tokens can be sold:
            int256(MAX_SUPPLY - WHITELIST_SUPPLY - LEGENDARY_SUPPLY + 1) * 2e18,
            0.014e18 // Time scale.
        )
    {
        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;

        mintStart = _mintStart;
        merkleRoot = _merkleRoot;

        goop = new Goop(address(this));
        pages = new Pages(_mintStart, address(goop), msg.sender);
        vault = LockupVault(_vault);

        goop.setPages(address(pages));

        BASE_URI = _baseUri;

        // Start price for legendary gobblers is 100 gobblers.
        legendaryGobblerAuctionData.currentLegendaryGobblerStartPrice = 100;

        // First legendary gobbler auction starts 30 days after the mint starts.
        legendaryGobblerAuctionData.currentLegendaryGobblerAuctionStart = uint120(_mintStart + 30 days);

        // Current legendary id starts at beginning of legendary id space.
        legendaryGobblerAuctionData.currentLegendaryId = uint16(LEGENDARY_GOBBLER_ID_START);
    }

    /*//////////////////////////////////////////////////////////////
                             WHITELIST LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint from whitelist, using a merkle proof.
    /// @param proof Merkle proof to verify the sender is whitelisted.
    function mintFromWhitelist(bytes32[] calldata proof) public {
        if (mintStart > block.timestamp || claimedWhitelist[msg.sender]) revert Unauthorized();

        if (!MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert Unauthorized();

        claimedWhitelist[msg.sender] = true;

        _mint(msg.sender, ++currentNonLegendaryId, "");
    }

    /*//////////////////////////////////////////////////////////////
                           GOOP MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a gobbler with goop, burning the cost.
    /// TODO: we might want to add a "max price arg" so ppl dont rekt on frontrun
    function mintFromGoop() public {
        // No need to check mint cap, gobblerPrice()
        // will revert due to overflow if we reach it.
        // It will also revert prior to the mint start.
        goop.burnForGobblers(msg.sender, gobblerPrice());

        _mint(msg.sender, ++currentNonLegendaryId, "");

        /// Every 9 goop mints, we should mint one gobbler to vault
        if (++numMintedFromGoop % 9 == 0) {
            _mint(address(vault), ++currentNonLegendaryId, "");
        }
    }

    /// @notice Gobbler pricing in terms of goop.
    /// @dev Will revert if called before minting starts
    /// or after all gobblers have been minted via VRGDA.
    function gobblerPrice() public view returns (uint256) {
        // We need checked math here to cause overflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        return getPrice(timeSinceStart, numMintedFromGoop);
    }

    /*//////////////////////////////////////////////////////////////
                     LEGENDARY GOBBLER AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a legendary gobbler by burning stakingMultiple standard gobblers.
    /// @param gobblerIds The ids of the standard gobblers to burn.
    // TODO: could this hit the gas limit?
    function mintLegendaryGobbler(uint256[] calldata gobblerIds) public {
        uint256 lastLegendaryId = legendaryGobblerAuctionData.currentLegendaryId;

        // TODO: wait wouldn't this mean the last legendaryId will be 9999
        // When legendary id equals max supply, we've minted all 10 legendary gobblers.
        if (lastLegendaryId == MAX_SUPPLY) revert NoRemainingLegendaryGobblers();

        // This will revert if the auction hasn't started yet, no need to check here as well.
        uint256 cost = legendaryGobblerPrice();

        if (gobblerIds.length != cost) revert InsufficientGobblerBalance();

        unchecked {
            uint256 burnedMultipleTotal; // The legendary's stakingMultiple will be 2x the sum of the gobblers burned.

            /*//////////////////////////////////////////////////////////////
                                    BATCH BURN LOGIC
            //////////////////////////////////////////////////////////////*/

            // Generate an amounts array locally to use in the event below.
            uint256[] memory amounts = new uint256[](gobblerIds.length);

            uint256 id; // Storing outside the loop saves ~7 gas per iteration.

            for (uint256 i = 0; i < gobblerIds.length; ++i) {
                id = gobblerIds[i];

                if (id >= LEGENDARY_GOBBLER_ID_START) revert CannotBurnLegendary();

                require(getGobblerData[id].owner == msg.sender, "WRONG_FROM");

                burnedMultipleTotal += getGobblerData[id].stakingMultiple;

                // TODO: SHOULD we clear attributes as well or just owner? even cheaper to clear attributes i think
                getGobblerData[id].owner = address(0);

                amounts[i] = 1;
            }

            emit TransferBatch(msg.sender, msg.sender, address(0), gobblerIds, amounts);

            /*//////////////////////////////////////////////////////////////
                                LEGENDARY MINTING LOGIC
            //////////////////////////////////////////////////////////////*/

            // Supply caps are properly checked above, so overflow should be impossible here.
            uint256 newLegendaryId = ++lastLegendaryId;

            // The shift right by 1 is equivalent to multiplication by 2, used to make
            // the legendary's stakingMultiple 2x the sum of the multiples of the gobblers burned.
            // Must be done before minting as the transfer hook will update the user's stakingMultiple.
            getGobblerData[newLegendaryId].stakingMultiple = uint48(burnedMultipleTotal << 1);

            // Update the user's staking data in one big batch. We add burnedMultipleTotal to their
            // staking multiple (not burnedMultipleTotal * 2) to account for the standard gobblers that
            // were burned and hence should have their multiples subtracted from the user's total multiple.
            getStakingDataForUser[msg.sender].lastBalance = uint128(goopBalance(msg.sender));
            getStakingDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);
            getStakingDataForUser[msg.sender].stakingMultiple += uint64(burnedMultipleTotal);

            // Start a new auction, 30 days after the previous start, and update the current legendary id.
            // The new start price is max of 100 and cost * 2. Shift left by 1 is like multiplication by 2.
            legendaryGobblerAuctionData.currentLegendaryId = uint16(newLegendaryId);
            legendaryGobblerAuctionData.currentLegendaryGobblerAuctionStart += 30 days;
            legendaryGobblerAuctionData.currentLegendaryGobblerStartPrice = uint120(cost < 50 ? 100 : cost << 1);

            // It gets a special event.
            emit LegendaryGobblerMint(newLegendaryId);

            // Mint the legendary gobbler.
            _mint(msg.sender, newLegendaryId, "");
        }
    }

    /// @notice Calculate the legendary gobbler price in terms of gobblers, according to linear decay function.
    /// @dev Reverts due to underflow if the auction has not yet begun. This is intended behavior and helps save gas.
    function legendaryGobblerPrice() public view returns (uint256) {
        uint256 daysSinceStart = (block.timestamp - legendaryGobblerAuctionData.currentLegendaryGobblerAuctionStart) /
            1 days;

        // If more than 30 days have passed, legendary gobbler is free, else, decay linearly over 30 days.
        // TODO: can we uncheck?
        return
            daysSinceStart >= 30
                ? 0 // TODO: why divide
                : (legendaryGobblerAuctionData.currentLegendaryGobblerStartPrice * (30 - daysSinceStart)) / 30;
    }

    /*//////////////////////////////////////////////////////////////
                                VRF LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the random seed for revealing gobblers.
    function getRandomSeed() public returns (bytes32) {
        // A random seed can only be requested when all gobblers from previous seed have been assigned.
        // This prevents a user from requesting additional randomness in hopes of a more favorable outcome.
        if (gobblersToBeAssigned != 0) revert Unauthorized();

        // Fix number of gobblers to be revealed from seed.
        gobblersToBeAssigned = uint128(currentNonLegendaryId - lastRevealedIndex);

        // Will revert if we don't have enough LINK to afford the request.
        return requestRandomness(chainlinkKeyHash, chainlinkFee);
    }

    /// @notice Callback from chainlink VRF. sets active attributes and seed.
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomSeed = randomness;
    }

    /*//////////////////////////////////////////////////////////////
                         ATTRIBUTES REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Knuth shuffle to progressively reveal gobblers using entropy from random seed.
    /// @param numGobblers The number of gobblers to reveal.
    function revealGobblers(uint256 numGobblers) public {
        // Can't reveal more gobblers than were available when seed was generated.
        if (numGobblers > gobblersToBeAssigned) revert Unauthorized();

        uint256 currentRandomSeed = randomSeed;

        uint256 currentLastRevealedIndex = lastRevealedIndex;

        // Implements a Knuth shuffle:
        for (uint256 i = 0; i < numGobblers; i++) {
            // Number of slots that have not been assigned.
            uint256 remainingSlots = LEGENDARY_GOBBLER_ID_START - lastRevealedIndex;

            // Randomly pick distance for swap.
            uint256 distance = currentRandomSeed % remainingSlots;

            // Select swap slot, adding distance to next reveal slot.
            uint256 swapSlot = currentLastRevealedIndex + 1 + distance;

            // If index in swap slot is 0, that means slot has never been touched, thus, it has the default value, which is the slot index.
            uint48 swapIndex = getGobblerData[swapSlot].idx == 0 ? uint48(swapSlot) : getGobblerData[swapSlot].idx;

            // Current slot is consecutive to last reveal.
            uint256 currentSlot = currentLastRevealedIndex + 1;

            // Again, we derive index based on value:
            uint48 currentIndex = getGobblerData[currentSlot].idx == 0
                ? uint48(currentSlot)
                : getGobblerData[currentSlot].idx;

            // Swap indices.
            getGobblerData[currentSlot].idx = swapIndex;
            getGobblerData[swapSlot].idx = currentIndex;

            // Select random attributes for current slot.
            currentRandomSeed = uint256(keccak256(abi.encodePacked(currentRandomSeed)));
            uint48 stakingMultiple = uint48(currentRandomSeed % 128) + 1; // todo: determine off-chain

            getGobblerData[currentSlot].stakingMultiple = stakingMultiple;

            address slotOwner = getGobblerData[currentSlot].owner;
            getStakingDataForUser[slotOwner].lastBalance = uint128(goopBalance(slotOwner));
            getStakingDataForUser[slotOwner].lastTimestamp = uint64(block.timestamp);
            getStakingDataForUser[slotOwner].stakingMultiple += stakingMultiple;

            // Increment last reveal index.
            currentLastRevealedIndex++;
        }

        // Update state all at once.
        randomSeed = currentRandomSeed;
        lastRevealedIndex = uint128(currentLastRevealedIndex);
        gobblersToBeAssigned -= uint128(numGobblers);
    }

    /*//////////////////////////////////////////////////////////////
                                URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a token's URI if it has been minted.
    /// @param gobblerId The id of the token to get the URI for.
    function uri(uint256 gobblerId) public view virtual override returns (string memory) {
        // Between 0 and lastRevealedIndex are revealed normal gobblers.
        if (gobblerId <= lastRevealedIndex) {
            // 0 is not a valid id:
            if (gobblerId == 0) return "";

            return string(abi.encodePacked(BASE_URI, uint256(getGobblerData[gobblerId].idx).toString()));
        }
        // Between lastRevealedIndex + 1 and currentNonLegendaryId are minted but not revealed.
        if (gobblerId <= currentNonLegendaryId) return UNREVEALED_URI;

        // Between currentNonLegendaryId and  LEGENDARY_GOBBLER_ID_START are unminted.
        if (gobblerId <= LEGENDARY_GOBBLER_ID_START) return "";

        // Between LEGENDARY_GOBBLER_ID_START and currentLegendaryId are minted legendaries.
        if (gobblerId <= legendaryGobblerAuctionData.currentLegendaryId)
            return string(abi.encodePacked(BASE_URI, gobblerId.toString()));

        return ""; // Unminted legendaries and invalid token ids.
    }

    /*//////////////////////////////////////////////////////////////
                            ART FEEDING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Feed a gobbler a work of art.
    /// @param gobblerId The gobbler to feed the page.
    /// @param nft The contract of the work of art.
    /// @param id The id of the work of art.
    /// @dev NFTs should be ERC1155s, ideally ERC1155Bs.
    function feedArt(
        uint256 gobblerId,
        address nft,
        uint256 id
    ) public {
        // The caller must own the gobbler they're feeding.
        if (getGobblerData[gobblerId].owner != msg.sender) revert Unauthorized();

        // In case the NFT is not an 1155B, prevent eating it twice.
        if (getGobblerFromFedArt[nft][id] != 0) revert AlreadyEaten();

        // We're assuming this is an 1155B-esque NFT, so we'll only transfer 1.
        ERC1155(nft).safeTransferFrom(msg.sender, address(this), id, 1, "");

        // Map the NFT to the gobbler that ate it.
        getGobblerFromFedArt[nft][id] = gobblerId;
    }

    /*//////////////////////////////////////////////////////////////
                              STAKING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate a user's staked goop balance.
    /// @param user The user to query balance for.
    function goopBalance(address user) public view returns (uint256) {
        // TODO: idt this accounts for wads
        // TODO: check i got the new formula without baserate right

        unchecked {
            uint256 stakingMultiple = getStakingDataForUser[user].stakingMultiple;
            uint256 lastBalance = getStakingDataForUser[user].lastBalance;
            uint256 timePassed = block.timestamp - getStakingDataForUser[user].lastTimestamp;

            // If a user's goop balance is greater than
            // 2**256 - 1 we've got much bigger problems.
            // Shift right by 2 is equivalent to division by 4.
            return
                lastBalance +
                ((stakingMultiple * (timePassed * timePassed)) >> 2) +
                // TODO: need to scale by 1e18 before sqrt i thinks
                (timePassed * FixedPointMathLib.sqrt(stakingMultiple * lastBalance));
        }
    }

    /// @notice Add goop to your staking balance.
    /// @param goopAmount The amount of goop to add.
    function addGoop(uint256 goopAmount) public {
        // Burn goop being added to gobbler.
        goop.burnForGobblers(msg.sender, goopAmount);

        unchecked {
            // If a user has enough goop to overflow their balance we've got big problems.
            getStakingDataForUser[msg.sender].lastBalance = uint128(goopBalance(msg.sender) + goopAmount);
            getStakingDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);
        }
    }

    /// @notice Remove goop from your staking balance.
    /// @param goopAmount The amount of goop to remove.
    function removeGoop(uint256 goopAmount) public {
        // Will revert due to underflow if removed amount is larger than the user's current goop balance.
        getStakingDataForUser[msg.sender].lastBalance = uint128(goopBalance(msg.sender) - goopAmount);
        getStakingDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);

        goop.mint(msg.sender, goopAmount);
    }

    /*//////////////////////////////////////////////////////////////
                          CONVENIENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Convenience function to get staking stakingMultiple for a gobbler.
    /// @param gobblerId The gobbler to get stakingMultiple for.
    function getGobblerStakingMultiple(uint256 gobblerId) public view returns (uint256) {
        return getGobblerData[gobblerId].stakingMultiple;
    }

    /// @notice Convenience function to get staking stakingMultiple for a user.
    /// @param user The user to get stakingMultiple for.
    function getUserStakingMultiple(address user) public view returns (uint256) {
        return getStakingDataForUser[user].stakingMultiple;
    }

    /*//////////////////////////////////////////////////////////////
                          ERC1155 TRANSFER HOOK
    //////////////////////////////////////////////////////////////*/

    /// @dev Only called on actual transfers, not mints and burns.
    function afterTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        uint128 idStakingMultiple = getGobblerData[id].stakingMultiple;

        unchecked {
            // Decrease the from user's stakingMultiple by the gobbler's stakingMultiple.
            getStakingDataForUser[from].lastBalance = uint128(goopBalance(from));
            getStakingDataForUser[from].lastTimestamp = uint64(block.timestamp);
            getStakingDataForUser[from].stakingMultiple -= uint64(idStakingMultiple);

            // Increase the to user's stakingMultiple by the gobbler's stakingMultiple.
            getStakingDataForUser[to].lastBalance = uint128(goopBalance(to));
            getStakingDataForUser[to].lastTimestamp = uint64(block.timestamp);
            getStakingDataForUser[to].stakingMultiple += uint64(idStakingMultiple);
        }
    }
}
