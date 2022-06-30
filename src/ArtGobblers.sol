// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";

import {VRGDA} from "./utils/VRGDA.sol";
import {LibString} from "./utils/LibString.sol";
import {LogisticVRGDA} from "./utils/LogisticVRGDA.sol";
import {MerkleProofLib} from "./utils/MerkleProofLib.sol";
import {GobblersERC1155B} from "./utils/GobblersERC1155B.sol";

import {Goo} from "./Goo.sol";

/// @title Art Gobblers NFT
/// @notice Art Gobblers scan the cosmos in search of art producing life.
contract ArtGobblers is GobblersERC1155B, LogisticVRGDA, VRFConsumerBase, Owned, ERC1155TokenReceiver {
    using LibString for uint256;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Goo ERC20 token contract.
    Goo public immutable goo;

    /// @notice The address which receives gobblers reserved for the team.
    address public immutable team;

    /// @notice The address which receives gobblers reserved for the community.
    address public immutable community;

    /*//////////////////////////////////////////////////////////////
                            SUPPLY CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable gobblers.
    uint256 public constant MAX_SUPPLY = 10000;

    /// @notice Maximum amount of gobblers mintable via mintlist.
    uint256 public constant MINTLIST_SUPPLY = 2000;

    /// @notice Maximum amount of mintable legendary gobblers.
    uint256 public constant LEGENDARY_SUPPLY = 10;

    /// @notice Maximum amount of gobblers split between the reserves.
    /// @dev Set to compromise 20% of the sum of goo mintable gobblers + reserved gobblers.
    uint256 public constant RESERVED_SUPPLY = (MAX_SUPPLY - MINTLIST_SUPPLY - LEGENDARY_SUPPLY) / 5;

    /// @notice Maximum amount of gobblers that can be minted via VRGDA.
    // prettier-ignore
    uint256 public constant MAX_MINTABLE = MAX_SUPPLY
        - MINTLIST_SUPPLY
        - LEGENDARY_SUPPLY
        - RESERVED_SUPPLY;

    /*//////////////////////////////////////////////////////////////
                           METADATA CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice The name displayed for the contract on Etherscan.
    string public constant name = "Art Gobblers";

    /// @notice URI for gobblers that have yet to be revealed.
    string public UNREVEALED_URI;

    /// @notice Base URI for minted gobblers.
    string public BASE_URI;

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
    mapping(address => bool) public hasClaimedMintlistGobbler;

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of minting.
    uint256 public immutable mintStart;

    /// @notice Number of gobblers minted from goo.
    uint128 public numMintedFromGoo;

    /*//////////////////////////////////////////////////////////////
                         STANDARD GOBBLER STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Id of the most recently minted non legendary gobbler.
    /// @dev Will be 0 if no non legendary gobblers have been minted yet.
    uint128 public currentNonLegendaryId;

    /// @notice The number of gobblers minted to the reserves.
    uint256 public numMintedForReserves;

    /*//////////////////////////////////////////////////////////////
                     LEGENDARY GOBBLER AUCTION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The last LEGENDARY_SUPPLY ids are reserved for legendary gobblers.
    uint256 public constant FIRST_LEGENDARY_GOBBLER_ID = MAX_SUPPLY - LEGENDARY_SUPPLY + 1;

    /// @notice Legendary auctions begin each time a multiple of these many gobblers have been minted.
    /// @dev We add 1 to LEGENDARY_SUPPLY because legendary auctions begin only after the first interval.
    uint256 public constant LEGENDARY_AUCTION_INTERVAL = MAX_MINTABLE / (LEGENDARY_SUPPLY + 1);

    /// @notice Struct holding data required for legendary gobbler auctions.
    struct LegendaryGobblerAuctionData {
        // Start price of current legendary gobbler auction.
        uint128 startPrice;
        // Number of legendary gobblers sold so far.
        uint128 numSold;
    }

    /// @notice Data about the current legendary gobbler auction.
    LegendaryGobblerAuctionData public legendaryGobblerAuctionData;

    /*//////////////////////////////////////////////////////////////
                          GOBBLER REVEAL STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding data required for gobbler reveals.
    struct GobblerRevealsData {
        // Last random seed obtained from VRF.
        uint64 randomSeed;
        // Next reveal cannot happen before this timestamp.
        uint64 nextRevealTimestamp;
        // Id of latest gobbler which has been revealed so far.
        uint56 lastRevealedId;
        // Remaining gobblers to be assigned from the current seed.
        uint56 toBeAssigned;
        // Whether we are waiting to receive a seed from Chainlink.
        bool waitingForSeed;
    }

    /// @notice Data about the current state of gobbler reveals.
    GobblerRevealsData public gobblerRevealsData;

    /*//////////////////////////////////////////////////////////////
                             EMISSION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct data info required for goo emission reward calculations.
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

    /// @notice Maps gobbler ids to NFT contracts and their ids to the # of those NFT ids fed to the gobbler.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public getCopiesOfArtFedToGobbler;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event GooAdded(address indexed user, uint256 gooAdded);
    event GooRemoved(address indexed user, uint256 gooAdded);

    event GobblerClaimed(address indexed user, uint256 indexed gobblerId);
    event GobblerPurchased(address indexed user, uint256 indexed gobblerId, uint256 price);
    event LegendaryGobblerMinted(address indexed user, uint256 indexed gobblerId, uint256[] burnedGobblerIds);
    event ReservedGobblersMinted(address indexed user, uint256 lastMintedGobblerId, uint256 numGobblersEach);

    event RandomnessRequested(address indexed user, uint256 toBeAssigned);
    event RandomnessFulfilled(uint256 randomness);

    event GobblersRevealed(address indexed user, uint256 numGobblers, uint256 lastRevealedId);

    event ArtFedToGobbler(address indexed user, uint256 indexed gobblerId, address indexed nft, uint256 id);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidProof();
    error AlreadyClaimed();
    error MintStartPending();

    error SeedPending();
    error RevealsPending();
    error RequestTooEarly();

    error ReserveImbalance();

    error OwnerMismatch(address owner);

    error NoRemainingLegendaryGobblers();
    error CannotBurnLegendary(uint256 gobblerId);
    error IncorrectGobblerAmount(uint256 provided, uint256 needed);

    error PriceExceededMax(uint256 currentPrice, uint256 maxPrice);

    error NotEnoughRemainingToBeAssigned(uint256 totalRemainingToBeAssigned);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        // Mint config:
        bytes32 _merkleRoot,
        uint256 _mintStart,
        // Addresses:
        Goo _goo,
        address _team,
        address _community,
        // Chainlink:
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        // URIs:
        string memory _baseUri,
        string memory _unrevealedUri
    )
        VRGDA(
            69.42e18, // Initial price.
            0.31e18 // Per period price decrease.
        )
        LogisticVRGDA(
            // Max mintable gobblers.
            int256(MAX_MINTABLE * 1e18),
            0.0023e18 // Time scale.
        )
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        Owned(msg.sender) // Deployer starts as owner.
    {
        mintStart = _mintStart;
        merkleRoot = _merkleRoot;

        goo = _goo;
        team = _team;
        community = _community;

        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;

        BASE_URI = _baseUri;
        UNREVEALED_URI = _unrevealedUri;

        // Starting price for legendary gobblers is 69 gobblers.
        legendaryGobblerAuctionData.startPrice = 69;

        // Reveal for initial mint must wait 24 hours
        gobblerRevealsData.nextRevealTimestamp = uint64(_mintStart + 1 days);
    }

    /*//////////////////////////////////////////////////////////////
                          MINTLIST CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim from mintlist, using a merkle proof.
    /// @param proof Merkle proof to verify the sender is mintlisted.
    /// @return gobblerId The id of the gobbler that was claimed.
    function claimGobbler(bytes32[] calldata proof) external returns (uint256 gobblerId) {
        // If minting has not yet begun, revert.
        if (mintStart > block.timestamp) revert MintStartPending();

        // If the user has already claimed, revert.
        if (hasClaimedMintlistGobbler[msg.sender]) revert AlreadyClaimed();

        // If the user's proof is invalid, revert.
        if (!MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();

        hasClaimedMintlistGobbler[msg.sender] = true; // Before mint to prevent reentrancy.

        unchecked {
            emit GobblerClaimed(msg.sender, gobblerId = ++currentNonLegendaryId);

            _mint(msg.sender, gobblerId, "");
        }
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a gobbler with goo, burning the cost.
    /// @param maxPrice Maximum price to pay to mint the gobbler.
    /// @return gobblerId The id of the gobbler that was minted.
    function mintFromGoo(uint256 maxPrice) external returns (uint256 gobblerId) {
        // No need to check mint cap, gobblerPrice()
        // will revert due to overflow if we reach it.
        // It will also revert prior to the mint start.
        uint256 currentPrice = gobblerPrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice, maxPrice);

        goo.burnForGobblers(msg.sender, currentPrice);

        unchecked {
            ++numMintedFromGoo; // Before mint to prevent reentrancy.

            emit GobblerPurchased(msg.sender, gobblerId = ++currentNonLegendaryId, currentPrice);

            _mint(msg.sender, gobblerId, "");
        }
    }

    /// @notice Gobbler pricing in terms of goo.
    /// @dev Will revert if called before minting starts
    /// or after all gobblers have been minted via VRGDA.
    function gobblerPrice() public view returns (uint256) {
        // We need checked math here to cause overflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        return getPrice(timeSinceStart, numMintedFromGoo);
    }

    /*//////////////////////////////////////////////////////////////
                     LEGENDARY GOBBLER AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a legendary gobbler by burning multiple standard gobblers.
    /// @param gobblerIds The ids of the standard gobblers to burn.
    /// @return gobblerId The id of the legendary gobbler that was minted.
    function mintLegendaryGobbler(uint256[] calldata gobblerIds) external returns (uint256 gobblerId) {
        gobblerId = FIRST_LEGENDARY_GOBBLER_ID + legendaryGobblerAuctionData.numSold; // Assign id.

        // If the gobbler id would be greater than the max supply, there are no remaining legendaries.
        if (gobblerId > MAX_SUPPLY) revert NoRemainingLegendaryGobblers();

        // This will revert if the auction hasn't started yet, no need to check here as well.
        uint256 cost = legendaryGobblerPrice();

        if (gobblerIds.length != cost) revert IncorrectGobblerAmount(gobblerIds.length, cost);

        // Overflow in here should not occur, as most math is on emission multiples, which are inherently small.
        unchecked {
            uint256 burnedMultipleTotal; // The legendary's emissionMultiple will be 2x the sum of the gobblers burned.

            /*//////////////////////////////////////////////////////////////
                                    BATCH BURN LOGIC
            //////////////////////////////////////////////////////////////*/

            // Generate an amounts array locally to use in the event below.
            uint256[] memory amounts = new uint256[](gobblerIds.length);

            uint256 id; // Storing outside the loop saves ~7 gas per iteration.

            for (uint256 i = 0; i < gobblerIds.length; ++i) {
                id = gobblerIds[i];

                if (id >= FIRST_LEGENDARY_GOBBLER_ID) revert CannotBurnLegendary(id);

                require(getGobblerData[id].owner == msg.sender, "WRONG_FROM");

                burnedMultipleTotal += getGobblerData[id].emissionMultiple;

                getGobblerData[id].owner = address(0);

                amounts[i] = 1;
            }

            emit TransferBatch(msg.sender, msg.sender, address(0), gobblerIds, amounts);

            /*//////////////////////////////////////////////////////////////
                                 LEGENDARY MINTING LOGIC
            //////////////////////////////////////////////////////////////*/

            // The shift right by 1 is equivalent to multiplication by 2, used to make
            // the legendary's emissionMultiple 2x the sum of the multiples of the gobblers burned.
            // Must be done before minting as the transfer hook will update the user's emissionMultiple.
            getGobblerData[gobblerId].emissionMultiple = uint48(burnedMultipleTotal << 1);

            // Update the user's emission data in one big batch. We add burnedMultipleTotal to their
            // emission multiple (not burnedMultipleTotal * 2) to account for the standard gobblers that
            // were burned and hence should have their multiples subtracted from the user's total multiple.
            getEmissionDataForUser[msg.sender].lastBalance = uint128(gooBalance(msg.sender));
            getEmissionDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);
            getEmissionDataForUser[msg.sender].emissionMultiple += uint64(burnedMultipleTotal);

            // New start price is the max of 69 and cost * 2. Left shift by 1 is like multiplication by 2.
            legendaryGobblerAuctionData.startPrice = uint120(cost < 35 ? 69 : cost << 1);
            legendaryGobblerAuctionData.numSold += 1; // Increment the # of legendaries sold.

            // If gobblerIds has 1,000 elements this should cost around ~270,000 gas.
            emit LegendaryGobblerMinted(msg.sender, gobblerId, gobblerIds);

            _mint(msg.sender, gobblerId, "");
        }
    }

    /// @notice Calculate the legendary gobbler price in terms of gobblers, according to a linear decay function.
    /// @dev The price of a legendary gobbler decays as gobblers are minted. The first legendary auction begins when
    /// 1 LEGENDARY_AUCTION_INTERVAL worth of gobblers are minted, and the price decays linearly while the next interval of
    /// gobblers is minted. Every time an additional interval is minted, a new auction begins until all legendaries been sold.
    function legendaryGobblerPrice() public view returns (uint256) {
        // Retrieve and cache the auction's startPrice and numSold on the stack.
        uint256 startPrice = legendaryGobblerAuctionData.startPrice;
        uint256 numSold = legendaryGobblerAuctionData.numSold;

        uint256 numMintedAtStart; // The number of gobblers minted at the start of the auction.

        unchecked {
            // The number of gobblers minted at the start of the auction is computed by multiplying the # of
            // intervals that must pass before the next auction begins by the number of gobblers in each interval.
            numMintedAtStart = (numSold + 1) * LEGENDARY_AUCTION_INTERVAL;
        }

        // How many gobblers where minted since auction began. Cannot be
        // unchecked, we want this to revert if auction has not yet started.
        uint256 numMintedSinceStart = numMintedFromGoo - numMintedAtStart;

        unchecked {
            // If we've minted the full interval, the price has decayed to 0.
            if (numMintedSinceStart >= LEGENDARY_AUCTION_INTERVAL) return 0;
            // Otherwise decay the price linearly based on what fraction of the interval has been minted.
            else return (startPrice * (LEGENDARY_AUCTION_INTERVAL - numMintedSinceStart)) / LEGENDARY_AUCTION_INTERVAL;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                VRF LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the random seed for revealing gobblers.
    function getRandomSeed() external returns (bytes32) {
        uint256 nextRevealTimestamp = gobblerRevealsData.nextRevealTimestamp;

        // A new random seed cannot be requested before the next reveal timestamp.
        if (block.timestamp < nextRevealTimestamp) revert RequestTooEarly();

        // A random seed can only be requested when all gobblers from previous seed have been assigned.
        // This prevents a user from requesting additional randomness in hopes of a more favorable outcome.
        if (gobblerRevealsData.toBeAssigned != 0) revert RevealsPending();

        // A new seed cannot be requested while we wait for a new seed.
        if (gobblerRevealsData.waitingForSeed) revert SeedPending();

        unchecked {
            // We want at most one batch of reveals every 24 hours.
            gobblerRevealsData.nextRevealTimestamp = uint64(nextRevealTimestamp + 1 days);

            // Fix number of gobblers to be revealed from seed.
            gobblerRevealsData.toBeAssigned = uint56(currentNonLegendaryId - gobblerRevealsData.lastRevealedId);

            // Prevent revealing while we wait for the seed.
            gobblerRevealsData.waitingForSeed = true;
        }

        emit RandomnessRequested(msg.sender, gobblerRevealsData.toBeAssigned);

        // Will revert if we don't have enough LINK to afford the request.
        return requestRandomness(chainlinkKeyHash, chainlinkFee);
    }

    /// @notice Callback from Chainlink VRF. Sets randomSeed.
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        // The unchecked cast to uint64 is equivalent to moduloing the randomness by 2**64.
        gobblerRevealsData.randomSeed = uint64(randomness); // 64 bits of randomness is plenty.

        gobblerRevealsData.waitingForSeed = false; // We have the seed now, open up reveals.

        emit RandomnessFulfilled(randomness);
    }

    /*//////////////////////////////////////////////////////////////
                          GOBBLER REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Knuth shuffle to progressively reveal gobblers using entropy from random seed.
    /// @param numGobblers The number of gobblers to reveal.
    function revealGobblers(uint256 numGobblers) external {
        uint256 randomSeed = gobblerRevealsData.randomSeed;

        uint256 lastRevealedId = gobblerRevealsData.lastRevealedId;

        uint256 totalRemainingToBeAssigned = gobblerRevealsData.toBeAssigned;

        // Can't reveal more gobblers than are currently remaining to be assigned in the seed.
        if (numGobblers > totalRemainingToBeAssigned) revert NotEnoughRemainingToBeAssigned(totalRemainingToBeAssigned);

        // Can't reveal if we're still waiting for a new seed.
        if (gobblerRevealsData.waitingForSeed) revert SeedPending();

        emit GobblersRevealed(msg.sender, numGobblers, lastRevealedId);

        // Implements a Knuth shuffle. If something in
        // here can overflow we've got bigger problems.
        unchecked {
            for (uint256 i = 0; i < numGobblers; ++i) {
                /*//////////////////////////////////////////////////////////////
                                      DETERMINE RANDOM SWAP
                //////////////////////////////////////////////////////////////*/

                // Number of ids that have not been revealed. Subtract 1
                // because we don't want to include any legendaries in the swap.
                uint256 remainingIds = FIRST_LEGENDARY_GOBBLER_ID - lastRevealedId - 1;

                // Randomly pick distance for swap.
                uint256 distance = randomSeed % remainingIds;

                // Current id is consecutive to last reveal.
                uint256 currentId = ++lastRevealedId;

                // Select swap id, adding distance to next reveal id.
                uint256 swapId = currentId + distance;

                /*//////////////////////////////////////////////////////////////
                                       GET INDICES FOR IDS
                //////////////////////////////////////////////////////////////*/

                // Get the index of the swap id.
                uint48 swapIndex = getGobblerData[swapId].idx == 0
                    ? uint48(swapId) // Hasn't been shuffled before.
                    : getGobblerData[swapId].idx; // Shuffled before.

                // Get the owner of the current id.
                address currentIdOwner = getGobblerData[currentId].owner;

                // Get the index of the current id.
                uint48 currentIndex = getGobblerData[currentId].idx == 0
                    ? uint48(currentId) // Hasn't been shuffled before.
                    : getGobblerData[currentId].idx; // Shuffled before.

                /*//////////////////////////////////////////////////////////////
                                  SWAP INDICES AND SET MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Determine the current id's new emission multiple.
                uint256 newCurrentIdMultiple = 9; // For beyond 7963.

                // The branchless expression below is equivalent to:
                //      if (swapIndex <= 3054) newCurrentIdMultiple = 6;
                // else if (swapIndex <= 5672) newCurrentIdMultiple = 7;
                // else if (swapIndex <= 7963) newCurrentIdMultiple = 8;
                assembly {
                    // prettier-ignore
                    newCurrentIdMultiple := sub(sub(sub(newCurrentIdMultiple,
                        lt(swapIndex, 7964)), lt(swapIndex, 5673)), lt(swapIndex, 3055)
                    )
                }

                // Swap the index and multiple of the current id.
                getGobblerData[currentId].idx = swapIndex;
                getGobblerData[currentId].emissionMultiple = uint48(newCurrentIdMultiple);

                // Swap the index of the swap id.
                getGobblerData[swapId].idx = currentIndex;

                /*//////////////////////////////////////////////////////////////
                                   UPDATE CURRENT ID MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Update the emission data for the owner of the current id.
                getEmissionDataForUser[currentIdOwner].lastBalance = uint128(gooBalance(currentIdOwner));
                getEmissionDataForUser[currentIdOwner].lastTimestamp = uint64(block.timestamp);
                getEmissionDataForUser[currentIdOwner].emissionMultiple += uint64(newCurrentIdMultiple);

                // Update the random seed to choose a new distance for the next iteration.
                // It is critical that we cast to uint64 here, as otherwise the random seed
                // set after calling revealGobblers(1) thrice would differ from the seed set
                // after calling revealGobblers(3) a single time. This would enable an attacker
                // to choose from a number of different seeds and use whichever is most favorable.
                // Equivalent to randomSeed = uint64(uint256(keccak256(abi.encodePacked(randomSeed))))
                assembly {
                    mstore(0, randomSeed) // Store the random seed in scratch space.

                    // Moduloing by 1 << 64 (2 ** 64) is equivalent to a uint64 cast.
                    randomSeed := mod(keccak256(0, 32), shl(64, 1))
                }
            }

            // Update all relevant reveal state state.
            gobblerRevealsData.randomSeed = uint64(randomSeed);
            gobblerRevealsData.lastRevealedId = uint56(lastRevealedId);
            gobblerRevealsData.toBeAssigned = uint56(totalRemainingToBeAssigned - numGobblers);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a token's URI if it has been minted.
    /// @param gobblerId The id of the token to get the URI for.
    function uri(uint256 gobblerId) public view virtual override returns (string memory) {
        // Between 0 and lastRevealed are revealed normal gobblers.
        if (gobblerId <= gobblerRevealsData.lastRevealedId) {
            // 0 is not a valid id:
            if (gobblerId == 0) return "";

            return string(abi.encodePacked(BASE_URI, uint256(getGobblerData[gobblerId].idx).toString()));
        }

        // Between lastRevealed + 1 and currentNonLegendaryId are minted but not revealed.
        if (gobblerId <= currentNonLegendaryId) return UNREVEALED_URI;

        // Between currentNonLegendaryId and FIRST_LEGENDARY_GOBBLER_ID are unminted.
        if (gobblerId < FIRST_LEGENDARY_GOBBLER_ID) return "";

        // Between FIRST_LEGENDARY_GOBBLER_ID and FIRST_LEGENDARY_GOBBLER_ID + numSold are minted legendaries.
        if (gobblerId < FIRST_LEGENDARY_GOBBLER_ID + legendaryGobblerAuctionData.numSold)
            return string(abi.encodePacked(BASE_URI, gobblerId.toString()));

        return ""; // Unminted legendaries and invalid token ids.
    }

    /*//////////////////////////////////////////////////////////////
                            ART FEEDING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Feed a gobbler a work of art.
    /// @param gobblerId The gobbler to feed the work of art.
    /// @param nft The ERC721 or ERC1155 contract of the work of art.
    /// @param id The id of the work of art.
    /// @param isERC1155 Whether the work of art is an ERC1155 token.
    function feedArt(
        uint256 gobblerId,
        address nft,
        uint256 id,
        bool isERC1155
    ) external {
        // Get the owner of the gobbler to feed.
        address owner = getGobblerData[gobblerId].owner;

        // The caller must own the gobbler they're feeding.
        if (owner != msg.sender) revert OwnerMismatch(owner);

        unchecked {
            // Increment the number of copies fed to the gobbler.
            // Counter overflow is unrealistic on human timescales.
            ++getCopiesOfArtFedToGobbler[gobblerId][nft][id];
        }

        emit ArtFedToGobbler(msg.sender, gobblerId, nft, id);

        isERC1155
            ? ERC1155(nft).safeTransferFrom(msg.sender, address(this), id, 1, "")
            : ERC721(nft).transferFrom(msg.sender, address(this), id);
    }

    /*//////////////////////////////////////////////////////////////
                             EMISSION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate a user's staked goo balance.
    /// @param user The user to query balance for.
    function gooBalance(address user) public view returns (uint256) {
        // If a user's goo balance is greater than
        // 2**256 - 1 we've got much bigger problems.
        unchecked {
            uint256 emissionMultiple = getEmissionDataForUser[user].emissionMultiple;
            uint256 lastBalanceWad = getEmissionDataForUser[user].lastBalance;

            // Stored with 18 decimals, such that if a day and a half elapsed this variable would equal 1.5e18.
            uint256 daysElapsedWad = ((block.timestamp - getEmissionDataForUser[user].lastTimestamp) * 1e18) / 1 days;

            uint256 daysElapsedSquaredWad = daysElapsedWad.mulWadDown(daysElapsedWad); // Need to use wad math here.

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.

            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * daysElapsedSquaredWad) >> 2) +

            daysElapsedWad.mulWadDown( // Terms are wads, so must mulWad.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                (emissionMultiple * lastBalanceWad * 1e18).sqrt()
            );
        }
    }

    /// @notice Add goo to your emission balance.
    /// @param gooAmount The amount of goo to add.
    function addGoo(uint256 gooAmount) external {
        // Burn goo being added to gobbler.
        goo.burnForGobblers(msg.sender, gooAmount);

        unchecked {
            // If a user has enough goo to overflow their balance we've got big problems.
            getEmissionDataForUser[msg.sender].lastBalance = uint128(gooBalance(msg.sender) + gooAmount);
            getEmissionDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);
        }

        emit GooAdded(msg.sender, gooAmount);
    }

    /// @notice Remove goo from your emission balance.
    /// @param gooAmount The amount of goo to remove.
    function removeGoo(uint256 gooAmount) external {
        // Will revert due to underflow if removed amount is larger than the user's current goo balance.
        getEmissionDataForUser[msg.sender].lastBalance = uint128(gooBalance(msg.sender) - gooAmount);
        getEmissionDataForUser[msg.sender].lastTimestamp = uint64(block.timestamp);

        emit GooRemoved(msg.sender, gooAmount);

        goo.mintForGobblers(msg.sender, gooAmount);
    }

    /*//////////////////////////////////////////////////////////////
                     RESERVED GOBBLERS MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of gobblers to the reserves.
    /// @param numGobblersEach The number of gobblers to mint to each reserve.
    /// @dev Gobblers minted to reserves cannot compromise more than 20% of the sum of
    /// the supply of goo minted gobblers and the supply of gobblers minted to reserves.
    function mintReservedGobblers(uint256 numGobblersEach) external returns (uint256 lastMintedGobblerId) {
        unchecked {
            // Optimistically increment numMintedForReserves, may be reverted below. Overflow in this
            // calculation is possible but numGobblersEach would have to be so large that it would cause the
            // loop in _batchMint to run out of gas quickly. Shift left by 1 is equivalent to multiplying by 2.
            uint256 newNumMintedForReserves = numMintedForReserves += (numGobblersEach << 1);

            // Ensure that after this mint gobblers minted to reserves won't compromise more than 20% of
            // the sum of the supply of goo minted gobblers and the supply of gobblers minted to reserves.
            if (newNumMintedForReserves > (numMintedFromGoo + newNumMintedForReserves) / 5) revert ReserveImbalance();
        }

        // First mint numGobblersEach gobblers to the team reserve.
        lastMintedGobblerId = _batchMint(team, numGobblersEach, currentNonLegendaryId, "");

        // Then mint numGobblersEach gobblers to the community reserve, and update currentNonLegendaryId.
        currentNonLegendaryId = uint128(
            lastMintedGobblerId = _batchMint(community, numGobblersEach, lastMintedGobblerId, "")
        );

        emit ReservedGobblersMinted(msg.sender, lastMintedGobblerId, numGobblersEach);
    }

    /*//////////////////////////////////////////////////////////////
                          CONVENIENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Convenience function to get emission emissionMultiple for a gobbler.
    /// @param gobblerId The gobbler to get emissionMultiple for.
    function getGobblerEmissionMultiple(uint256 gobblerId) external view returns (uint256) {
        return getGobblerData[gobblerId].emissionMultiple;
    }

    /// @notice Convenience function to get emission emissionMultiple for a user.
    /// @param user The user to get emissionMultiple for.
    function getUserEmissionMultiple(address user) external view returns (uint256) {
        return getEmissionDataForUser[user].emissionMultiple;
    }

    /*//////////////////////////////////////////////////////////////
                             ERC1155B LOGIC
    //////////////////////////////////////////////////////////////*/

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        unchecked {
            uint64 emissionsMultipleTotal; // Will use to set each user's multiple.

            for (uint256 i = 0; i < ids.length; i++) {
                id = ids[i];
                amount = amounts[i];

                // Can only transfer from the owner.
                require(from == getGobblerData[id].owner, "WRONG_FROM");

                // Can only transfer 1 with ERC1155B.
                require(amount == 1, "INVALID_AMOUNT");

                getGobblerData[id].owner = to;

                emissionsMultipleTotal += getGobblerData[id].emissionMultiple;
            }

            transferUserEmissionMultiple(from, to, emissionsMultipleTotal);
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        require(from == getGobblerData[id].owner, "WRONG_FROM"); // Can only transfer from the owner.

        // Can only transfer 1 with ERC1155B.
        require(amount == 1, "INVALID_AMOUNT");

        getGobblerData[id].owner = to;

        transferUserEmissionMultiple(from, to, getGobblerData[id].emissionMultiple);

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    /*//////////////////////////////////////////////////////////////
                              HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Transfer an amount of a user's emission's multiple to another user.
    /// @dev Should be done whenever a gobbler is transferred between two users.
    /// @param from The user to transfer the amount of emission multiple from.
    /// @param to The user to transfer the amount of emission multiple to.
    /// @param emissionMultiple The amount of emission multiple to transfer.
    function transferUserEmissionMultiple(
        address from,
        address to,
        uint64 emissionMultiple
    ) internal {
        unchecked {
            // Decrease the from user's emissionMultiple by the gobbler's emissionMultiple.
            getEmissionDataForUser[from].lastBalance = uint128(gooBalance(from));
            getEmissionDataForUser[from].lastTimestamp = uint64(block.timestamp);
            getEmissionDataForUser[from].emissionMultiple -= emissionMultiple;

            // Increase the to user's emissionMultiple by the gobbler's emissionMultiple.
            getEmissionDataForUser[to].lastBalance = uint128(gooBalance(to));
            getEmissionDataForUser[to].lastTimestamp = uint64(block.timestamp);
            getEmissionDataForUser[to].emissionMultiple += emissionMultiple;
        }
    }
}
