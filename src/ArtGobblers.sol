// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {FixedPointMathLib as Math} from "solmate/utils/FixedPointMathLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";

import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";

import {VRGDA} from "./utils/VRGDA.sol";
import {LogisticVRGDA} from "./utils/LogisticVRGDA.sol";
import {GobblersERC1155B} from "./utils/GobblersERC1155B.sol";

import {Goop} from "./Goop.sol";
import {Pages} from "./Pages.sol";

// TODO: events

/// @title Art Gobblers NFT
/// @notice Art Gobblers scan the cosmos in search of art producing life.
contract ArtGobblers is GobblersERC1155B, LogisticVRGDA, VRFConsumerBase, ERC1155TokenReceiver {
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    Goop public immutable goop;

    address public immutable team;

    /*//////////////////////////////////////////////////////////////
                            SUPPLY CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable gobblers.
    uint256 public constant MAX_SUPPLY = 10000;

    /// @notice Maximum amount of gobblers mintable via mintlist.
    uint256 public constant MINTLIST_SUPPLY = 2000;

    /// @notice Maximum amount of mintable leader gobblers.
    uint256 public constant LEADER_SUPPLY = 10;

    /// @notice Maximum amount of gobblers that will go to the team.
    /// @dev 10% of the supply of non-leader/mintlist gobblers.
    uint256 public constant TEAM_SUPPLY = 799;

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
                             MINTLIST STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Merkle root of mint mintlist.
    bytes32 public immutable merkleRoot;

    /// @notice Mapping to keep track of which addresses have claimed from mintlist.
    mapping(address => bool) public claimedMintlist;

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of the mintlist & VRGDA mint.
    uint256 public immutable mintStart;

    /// @notice Number of gobblers minted from goop.
    uint128 public numMintedFromGoop;

    /*//////////////////////////////////////////////////////////////
                         STANDARD GOBBLER STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Id of last minted non leader token.
    uint128 internal currentNonLeaderId; // TODO: public?

    /*//////////////////////////////////////////////////////////////
                      LEADER GOBBLER AUCTION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Last 10 ids are reserved for leader gobblers.
    uint256 private constant LEADER_GOBBLER_ID_START = MAX_SUPPLY - 10;

    /// @notice Struct holding info required for leader gobbler auctions.
    struct LeaderGobblerAuctionData {
        // Start price of current leader gobbler auction.
        uint120 currentLeaderGobblerStartPrice;
        // Start timestamp of current leader gobbler auction.
        uint120 currentLeaderGobblerAuctionStart;
        // Id of last minted leader gobbler.
        // 16 bits has a max value of ~60,000,
        // which is safely within our limits here.
        uint16 currentLeaderId; // TODO: current leader id is kinda confusing cuz the first id isnt actually leader
    }

    /// @notice Data about the current leader gobbler auction.
    LeaderGobblerAuctionData public leaderGobblerAuctionData;

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

    /// @notice Next reveal cannot happen before this timestamp
    uint256 public nextRevealTimestamp;

    /*//////////////////////////////////////////////////////////////
                              EMISSION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding info required for goop emission reward calculations.
    struct EmissionData {
        // The sum of the multiples of all gobblers the user holds.
        uint64 emissionMultiple;
        // Balance at time of last deposit or withdrawal.
        uint128 lastBalance;
        // Timestamp of last deposit or withdrawal.
        uint64 lastTimestamp;
    }

    /// @notice Maps user addresses to their emission data.
    mapping(address => EmissionData) public getEmissionDataForUser;

    /*//////////////////////////////////////////////////////////////
                            ART FEEDING STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from NFT contracts to their ids to gobbler ids they were fed to.
    mapping(address => mapping(uint256 => uint256)) public getGobblerFromFedArt;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Leader gobbler was minted.
    event LeaderGobblerMint(uint256 gobblerId);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    error AlreadyEaten();

    error CannotBurnLeader();

    error IncorrectGobblerAmount();

    error NoRemainingLeaderGobblers();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        // Whitelist:
        bytes32 _merkleRoot,
        uint256 _mintStart,
        // Addresses:
        Goop _goop,
        address _team,
        // Chainlink:
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        // URI:
        string memory _baseUri
    )
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        VRGDA(
            6.9e18, // Initial price.
            0.31e18 // Per period price decrease.
        )
        LogisticVRGDA(
            // Logistic scale. We multiply by 2x (scaled by 1e18) to account for the
            // subtracted initial value, and add 1 to ensure all the tokens can be sold:
            int256((MAX_SUPPLY - MINTLIST_SUPPLY - LEADER_SUPPLY - TEAM_SUPPLY) + 1) * 2e18,
            0.014e18 // Time scale.
        )
    {
        mintStart = _mintStart;
        merkleRoot = _merkleRoot;

        goop = _goop;
        team = _team;

        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;

        BASE_URI = _baseUri;

        // Start price for leader gobblers is 100 gobblers.
        leaderGobblerAuctionData.currentLeaderGobblerStartPrice = 100;

        // First leader gobbler auction starts 30 days after the mint starts.
        leaderGobblerAuctionData.currentLeaderGobblerAuctionStart = uint120(_mintStart + 30 days);

        // Current leader id starts at beginning of leader id space.
        leaderGobblerAuctionData.currentLeaderId = uint16(LEADER_GOBBLER_ID_START);

        // Reveal for initial mint must wait 24 hours
        nextRevealTimestamp = _mintStart + 1 days;
    }

    /*//////////////////////////////////////////////////////////////
                             MINTLIST LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint from mintlist, using a merkle proof.
    /// @param proof Merkle proof to verify the sender is mintlisted.
    function mintFromMintlist(bytes32[] calldata proof) public {
        if (mintStart > block.timestamp || claimedMintlist[msg.sender]) revert Unauthorized();

        if (!MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert Unauthorized();

        claimedMintlist[msg.sender] = true;

        unchecked {
            _mint(msg.sender, ++currentNonLeaderId, "");
        }
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

        unchecked {
            _mint(msg.sender, ++currentNonLeaderId, "");

            // Every 9 goop mints, we mint one gobbler for the team.
            if (++numMintedFromGoop % 9 == 0) _mint(address(team), ++currentNonLeaderId, "");
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
                      LEADER GOBBLER AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a leader gobbler by burning multiple standard gobblers.
    /// @param gobblerIds The ids of the standard gobblers to burn.
    // TODO: could this hit the gas limit?
    function mintLeaderGobbler(uint256[] calldata gobblerIds) public {
        uint256 lastLeaderId = leaderGobblerAuctionData.currentLeaderId;

        // TODO: wait wouldn't this mean the last leaderId will be 9999
        // When leader id equals max supply, we've minted all 10 leader gobblers.
        if (lastLeaderId == MAX_SUPPLY) revert NoRemainingLeaderGobblers();

        // This will revert if the auction hasn't started yet, no need to check here as well.
        uint256 cost = leaderGobblerPrice();

        if (gobblerIds.length != cost) revert IncorrectGobblerAmount();

        // Overflow in here should not occur, as most math is on emission multiples, which are inherently small.
        unchecked {
            uint256 burnedMultipleTotal; // The leader's emissionMultiple will be 2x the sum of the gobblers burned.

            /*//////////////////////////////////////////////////////////////
                                    BATCH BURN LOGIC
            //////////////////////////////////////////////////////////////*/

            // Generate an amounts array locally to use in the event below.
            uint256[] memory amounts = new uint256[](gobblerIds.length);

            uint256 id; // Storing outside the loop saves ~7 gas per iteration.

            for (uint256 i = 0; i < gobblerIds.length; ++i) {
                id = gobblerIds[i];

                if (id >= LEADER_GOBBLER_ID_START) revert CannotBurnLeader();

                require(getGobblerData[id].owner == msg.sender, "WRONG_FROM");

                burnedMultipleTotal += getGobblerData[id].emissionMultiple;

                getGobblerData[id].owner = address(0);

                amounts[i] = 1;
            }

            emit TransferBatch(msg.sender, msg.sender, address(0), gobblerIds, amounts);

            /*//////////////////////////////////////////////////////////////
                                LEADER MINTING LOGIC
            //////////////////////////////////////////////////////////////*/

            // Supply caps are properly checked above, so overflow should be impossible here.
            uint256 newLeaderId = ++lastLeaderId;

            // The shift right by 1 is equivalent to multiplication by 2, used to make
            // the leader's emissionMultiple 2x the sum of the multiples of the gobblers burned.
            // Must be done before minting as the transfer hook will update the user's emissionMultiple.
            getGobblerData[newLeaderId].emissionMultiple = uint48(burnedMultipleTotal << 1);

            // Update the user's emission data in one big batch. We add burnedMultipleTotal to their
            // emission multiple (not burnedMultipleTotal * 2) to account for the standard gobblers that
            // were burned and hence should have their multiples subtracted from the user's total multiple.
            getEmissionDataForUser[msg.sender].lastBalance = uint128(goopBalance(msg.sender));
            getEmissionDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);
            getEmissionDataForUser[msg.sender].emissionMultiple += uint64(burnedMultipleTotal);

            // Start a new auction, 30 days after the previous start, and update the current leader id.
            // The new start price is max of 100 and cost * 2. Shift left by 1 is like multiplication by 2.
            leaderGobblerAuctionData.currentLeaderId = uint16(newLeaderId);
            leaderGobblerAuctionData.currentLeaderGobblerAuctionStart += 30 days;
            leaderGobblerAuctionData.currentLeaderGobblerStartPrice = uint120(cost < 50 ? 100 : cost << 1);

            // It gets a special event.
            emit LeaderGobblerMint(newLeaderId);

            // Mint the leader gobbler.
            _mint(msg.sender, newLeaderId, "");
        }
    }

    /// @notice Calculate the leader gobbler price in terms of gobblers, according to linear decay function.
    /// @dev Reverts due to underflow if the auction has not yet begun. This is intended behavior and helps save gas.
    function leaderGobblerPrice() public view returns (uint256) {
        // Cannot be unchecked, we want this to revert if the auction has not started yet.
        uint256 daysSinceStart = (block.timestamp - leaderGobblerAuctionData.currentLeaderGobblerAuctionStart) / 1 days;

        // If 30 or more days have passed, leader gobbler is free.
        if (daysSinceStart >= 30) return 0;

        unchecked {
            // If we're less than 30 days into the auction, the price simply decays linearly until the 30th day.
            return (leaderGobblerAuctionData.currentLeaderGobblerStartPrice * (30 - daysSinceStart)) / 30;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                VRF LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the random seed for revealing gobblers.
    function getRandomSeed() public returns (bytes32) {
        uint256 nextReveal = nextRevealTimestamp;

        // A new random seed cannot be requested before the next reveal timestamp.
        if (block.timestamp < nextReveal) revert Unauthorized();

        // A random seed can only be requested when all gobblers from previous seed have been assigned.
        // This prevents a user from requesting additional randomness in hopes of a more favorable outcome.
        if (gobblersToBeAssigned != 0) revert Unauthorized();

        unchecked {
            // We want at most one batch of reveals every 24 hours.
            nextRevealTimestamp = nextReveal + 1 days;

            // Fix number of gobblers to be revealed from seed.
            gobblersToBeAssigned = uint128(currentNonLeaderId - lastRevealedIndex);
        }

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
        uint256 currentGobblersToBeAssigned = gobblersToBeAssigned;

        // Can't reveal more gobblers than were available when seed was generated.
        if (numGobblers > currentGobblersToBeAssigned) revert Unauthorized();

        uint256 currentRandomSeed = randomSeed;

        uint256 currentLastRevealedIndex = lastRevealedIndex;

        // Implements a Knuth shuffle. If something in
        // here can overflow we've got bigger problems.
        unchecked {
            for (uint256 i = 0; i < numGobblers; i++) {
                /*//////////////////////////////////////////////////////////////
                                          CHOOSE SLOTS
                //////////////////////////////////////////////////////////////*/

                // Number of slots that have not been assigned.
                uint256 remainingSlots = LEADER_GOBBLER_ID_START - lastRevealedIndex;

                // Randomly pick distance for swap.
                uint256 distance = currentRandomSeed % remainingSlots;

                // Current slot is consecutive to last reveal.
                uint256 currentSlot = currentLastRevealedIndex + 1;

                // Select swap slot, adding distance to next reveal slot.
                uint256 swapSlot = currentSlot + distance;

                /*//////////////////////////////////////////////////////////////
                                       RETRIEVE SLOT DATA
                //////////////////////////////////////////////////////////////*/

                // Get the index of the swap slot.
                uint48 swapIndex = getGobblerData[swapSlot].idx == 0
                    ? uint48(swapSlot) // Slot is untouched.
                    : getGobblerData[swapSlot].idx;

                // Get the owner of the current slot.
                address currentSlotOwner = getGobblerData[currentSlot].owner;

                // Get the index of the current slot.
                uint48 currentIndex = getGobblerData[currentSlot].idx == 0
                    ? uint48(currentSlot) // Slot is untouched.
                    : getGobblerData[currentSlot].idx;

                /*//////////////////////////////////////////////////////////////
                                  SWAP INDEXES AND SET MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Determine the current slot's new emission multiple.
                uint256 newCurrentSlotMultiple = 9; // For beyond 7963.
                if (swapIndex <= 3054) newCurrentSlotMultiple = 6;
                else if (swapIndex <= 5672) newCurrentSlotMultiple = 7;
                else if (swapIndex <= 7963) newCurrentSlotMultiple = 8;

                // Swap the index and multiple of the current slot.
                getGobblerData[currentSlot].idx = swapIndex;
                getGobblerData[currentSlot].emissionMultiple = uint48(newCurrentSlotMultiple);

                // Swap the index of the swap slot.
                getGobblerData[swapSlot].idx = currentIndex;

                /*//////////////////////////////////////////////////////////////
                                  UPDATE CURRENT SLOT MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Update the emission data for the owner of the current slot.
                getEmissionDataForUser[currentSlotOwner].lastBalance = uint128(goopBalance(currentSlotOwner));
                getEmissionDataForUser[currentSlotOwner].lastTimestamp = uint64(block.timestamp);
                getEmissionDataForUser[currentSlotOwner].emissionMultiple += uint64(newCurrentSlotMultiple);

                /*//////////////////////////////////////////////////////////////
                                             CLEANUP
                //////////////////////////////////////////////////////////////*/

                ++currentLastRevealedIndex; // Update the last reveal index and random seed.
                currentRandomSeed = uint256(keccak256(abi.encodePacked(currentRandomSeed)));
            }

            // Update state all at once.
            randomSeed = currentRandomSeed;
            lastRevealedIndex = uint128(currentLastRevealedIndex);
            gobblersToBeAssigned = uint128(currentGobblersToBeAssigned - numGobblers);
        }
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

        // Between lastRevealedIndex + 1 and currentNonLeaderId are minted but not revealed.
        if (gobblerId <= currentNonLeaderId) return UNREVEALED_URI;

        // Between currentNonLeaderId and LEADER_GOBBLER_ID_START are unminted.
        if (gobblerId <= LEADER_GOBBLER_ID_START) return "";

        // Between LEADER_GOBBLER_ID_START and currentLeaderId are minted leaders.
        if (gobblerId <= leaderGobblerAuctionData.currentLeaderId)
            return string(abi.encodePacked(BASE_URI, gobblerId.toString()));

        return ""; // Unminted leaders and invalid token ids.
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
                             EMISSION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate a user's staked goop balance.
    /// @param user The user to query balance for.
    function goopBalance(address user) public view returns (uint256) {
        // If a user's goop balance is greater than
        // 2**256 - 1 we've got much bigger problems.
        unchecked {
            uint256 emissionMultiple = getEmissionDataForUser[user].emissionMultiple;
            uint256 lastBalanceWad = getEmissionDataForUser[user].lastBalance;

            // Stored with 18 decimals, such that if a day and a half elapsed this variable would equal 1.5e18.
            uint256 daysElapsedWad = ((block.timestamp - getEmissionDataForUser[user].lastTimestamp) * 1e18) / 1 days;

            uint256 daysElapsedSquaredWad = Math.mulWadDown(daysElapsedWad, daysElapsedWad); // Need to use wad math here.

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.
                
            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * daysElapsedSquaredWad) >> 2) +

            Math.mulWadDown(
                daysElapsedWad, // Must mulWad because both terms are wads.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                Math.sqrt(emissionMultiple * lastBalanceWad * 1e18)
            );
        }
    }

    /// @notice Add goop to your emission balance.
    /// @param goopAmount The amount of goop to add.
    function addGoop(uint256 goopAmount) public {
        // Burn goop being added to gobbler.
        goop.burnForGobblers(msg.sender, goopAmount);

        unchecked {
            // If a user has enough goop to overflow their balance we've got big problems.
            getEmissionDataForUser[msg.sender].lastBalance = uint128(goopBalance(msg.sender) + goopAmount);
            getEmissionDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);
        }
    }

    /// @notice Remove goop from your emission balance.
    /// @param goopAmount The amount of goop to remove.
    function removeGoop(uint256 goopAmount) public {
        // Will revert due to underflow if removed amount is larger than the user's current goop balance.
        getEmissionDataForUser[msg.sender].lastBalance = uint128(goopBalance(msg.sender) - goopAmount);
        getEmissionDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);

        goop.mintForGobblers(msg.sender, goopAmount);
    }

    /*//////////////////////////////////////////////////////////////
                          CONVENIENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Convenience function to get emission emissionMultiple for a gobbler.
    /// @param gobblerId The gobbler to get emissionMultiple for.
    function getGobblerEmissionMultiple(uint256 gobblerId) public view returns (uint256) {
        return getGobblerData[gobblerId].emissionMultiple;
    }

    /// @notice Convenience function to get emission emissionMultiple for a user.
    /// @param user The user to get emissionMultiple for.
    function getUserEmissionMultiple(address user) public view returns (uint256) {
        return getEmissionDataForUser[user].emissionMultiple;
    }

    /*//////////////////////////////////////////////////////////////
                          ERC1155 TRANSFER HOOK
    //////////////////////////////////////////////////////////////*/

    // TODO: possible optimization is to manually override batch transfer cuz from will always be the same

    /// @dev Only called on actual transfers, not mints and burns.
    function afterTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        uint128 idEmissionMultiple = getGobblerData[id].emissionMultiple;

        unchecked {
            // Decrease the from user's emissionMultiple by the gobbler's emissionMultiple.
            getEmissionDataForUser[from].lastBalance = uint128(goopBalance(from));
            getEmissionDataForUser[from].lastTimestamp = uint64(block.timestamp);
            getEmissionDataForUser[from].emissionMultiple -= uint64(idEmissionMultiple);

            // Increase the to user's emissionMultiple by the gobbler's emissionMultiple.
            getEmissionDataForUser[to].lastBalance = uint128(goopBalance(to));
            getEmissionDataForUser[to].lastTimestamp = uint64(block.timestamp);
            getEmissionDataForUser[to].emissionMultiple += uint64(idEmissionMultiple);
        }
    }
}
