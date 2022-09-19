// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*                                                                              **,/*,
                                                                     *%@&%#/*,,..........,/(%&@@#*
                                                                 %@%,..............................#@@%
                                                              &&,.....,,...............................,/&@*
                                                            (@*.....**............,/,.......................(@%
                                                           &&......*,............./,.............**............&@
                                                          @#......**.............**..............,*........,*,..,@/
                                                         /@......,/............../,..............,*........../,..*@.
                                                        #@,......................*.............../,..........**...#/
                                                      ,@&,.......................................*..........,/....(@
                                                  *@&(*...................................................../*....(@
                                                 @(..*%@@&%#(#@@@%%%%%&&@@@@@@@@@&&#(///..........................#@
                                                 @%/@@@&%&&&@@&%%%%%%%#(/(((/(/(/(/(/(/(/(/(%%&@@@%(/,............#&
                                                  @@@#/**./@%%%&%#/*************./(%@@@@&(*********(@&&@@@%(.....,&@
                                                 ,@/.//(&@@/.     .#@%/******./&&*,      ./@&********%@/**(@#@@#,..(@
                                                 #%****%@.           %@/****./&@      ,.    %&********%@(**&@...(@#.#@
                                                 &#**./@/  %@&&      .@#****./@*    &@@@@&  .@/******./@@((((@&....(@
                                                 ##**./&@ ,&@@@,     #@/****./@@      @@.  .@&*******./@%****%@@@(,
                                                 ,@/**./%@(.      .*@@/********(&@#*,,,,/&@%/*******./@@&&&@@@#
                                                   @&/**@&/%&&&&&%/**.//////*********./************./@&******@*
                                                     /@@@@&(////#%&@@&(**./#&@@&(//*************./&@(********#@
                                                       .@#**.///*****************(#@@@&&&&&@@@@&%(**********./@,
                                                       @(*****%@#*********************&@#*********************(@
                                                       @****./@#*./@@#//***.///(%@%*****%@*********************#@
                                                      #&****./@%************************&@**********************@%
                                                     .@/******.//*******************./@@(************************@/
                                                     /@**********************************************************(@,
                                                     @#*****************************************************%@@@@@@@.
                                                    *@/*************************************************************#@(
                                                    @%***************************************************************./@(
                     /@@&&&@@                     .@/*******************************************************************&@
                    @%######%@.                   @#***************************./%&&&%(**************#%******************&#
                    @%######&@%&@@.             ,@(***./&#********************#@&#####%@&*************&%****************./@,
               &&*,/@%######&@@@*.*@&,         @@****./@&*******************./%@#######%@#***********./@&*****************(@
              ((...*%@&##%@@,..........,,,,%@&@%/*****&%****************./&@#*%@#######&@*#@%*********./@&*****************(@,
              (@#....(@%#&&,...,/...........@(*******(@(****************(@/...*%@@@@@@%*....&@@@@&@@@@@@%/%@@##(************(@.
              ((./(((%@%#&@/,/&@/...........%&*******%@****************./@%,.................#,............/@%***************#@
              *@@####@@%###%&@(@(...........%&*******%@****************%@,,#%/..............................#@/***************&/
              (#.....,&&####&@..%%..........%%*****(@@#****************#@,...................................@(***************(@
              .@@&%%&@@&####&&.............,@(***%@(**********./#%%%%%##&@&#(,...............................#@****************&.
               &#.....(@%###&@*............%@**%@(*******(&@&%#/////////@%...................................#@***************&@
                 #@@@@&%####&@&&&,........%@./@%*****(@@%////////////////@@@%,...............................#@**************#@
                     @@&&&&@@(    /&@@&%%@&@@@%**./&@(///////////////////@%.................................,@(*********./%@&.
                      (@//@%                @%***&&(//////////////////////(&@(**,,,,./(%&@@@%/*,,****,,***./@@&&&&&&&&#//%@
                      (@//%@               (@(*#@#////////////////////////////%@@%%%&@@#////%@/***************************&&
                      (@//%@  .,,,,/#&&&&&&@&*#@#///////////////////////////////@%//&&///////#@(***************************@&(#@@@@@&(*.
               ,@@@@@&&@//%@,,.,,,,,.,..,,#@./@%////////////////////////////////%@**&&////////(@(**************************&#,,,,,,,,,,,,/(#&@&
          &@%*,,,,,,,,#@//%@,,,,,,,,,,,,,,&%*#@(////////////////////////////////%@**&&/////////&@**************************#@.,,,.,,.,,&#.,,...,%@
       (@/,,,,,,,,,,,,(@(/%@,,,,,,,,,,,,,,&%*#@(////////////////////////////////%@./%@/////////#@(*************************&%,,,(%@@@@#*,.     .,/@.
      &%..    *&@%/,.,#@(*#@*,,.,,,,,,,,,,%@/#@(////////////////////////////////%@**#@/////////#@(*****************.//#%@@@@%%(/,...        ...,,,%&
     ,@*.,.       ../((%&&@@@&%#((///,,,,,/@&(@(////////////////////////////////@&**#@/////////%@%###%&&&&@@@@@@%%#(**,,,,,,.         ..,,,,,,,,,,%#
      @(,,,,,..,            ,..   ..,,,**(%%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%(((,,.,.,,,,,,.,..,,,,.,.,,,,.,..,.,,.,,,,,.,,,,,,,,,.*@%
       @%,,,,,,,,,,,,,,,.,.,,,      .,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,.,,,,,,#@@,
        ,@@(,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,.,,.,.,./#%&@@@@@#
         .@#&@@@@@%*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/&@@@@@%&@%((((#@@.
          .@%((((#@@@/#&@@@@&%#/*,.,..,,,,.,,,,,.,.,,,,,,,,,,,,,,,,..,.,..,,...,,,...,,,,,,.,,,,,,,,,,,../#%&@@@@@@@&%((///*********./(((/&&
             %@&%%#/***********./////(((((((####%%&&@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@&&%%%%%%%%#((((((((%@&#(((((#%@%/*******************./*/

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {toWadUnsafe, toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LibGOO} from "goo-issuance/LibGOO.sol";
import {LogisticVRGDA} from "VRGDAs/LogisticVRGDA.sol";

import {RandProvider} from "./utils/rand/RandProvider.sol";
import {GobblersERC721} from "./utils/token/GobblersERC721.sol";

import {Goo} from "./Goo.sol";
import {Pages} from "./Pages.sol";

/// @title Art Gobblers NFT
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author transmissions11 <t11s@paradigm.xyz>
/// @notice An experimental decentralized art factory by Justin Roiland and Paradigm.
contract ArtGobblers is GobblersERC721, LogisticVRGDA, Owned, ERC1155TokenReceiver {
    using LibString for uint256;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Goo ERC20 token contract.
    Goo public immutable goo;

    /// @notice The address of the Pages ERC721 token contract.
    Pages public immutable pages;

    /// @notice The address which receives gobblers reserved for the team.
    address public immutable team;

    /// @notice The address which receives gobblers reserved for the community.
    address public immutable community;

    /// @notice The address of a randomness provider. This provider will initially be
    /// a wrapper around Chainlink VRF v1, but can be changed in case it is fully sunset.
    RandProvider public randProvider;

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
    /// @dev Set to comprise 20% of the sum of goo mintable gobblers + reserved gobblers.
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

    /// @notice URI for gobblers that have yet to be revealed.
    string public UNREVEALED_URI;

    /// @notice Base URI for minted gobblers.
    string public BASE_URI;

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

    /// @notice Initial legendary gobbler auction price.
    uint256 public constant LEGENDARY_GOBBLER_INITIAL_START_PRICE = 69;

    /// @notice The last LEGENDARY_SUPPLY ids are reserved for legendary gobblers.
    uint256 public constant FIRST_LEGENDARY_GOBBLER_ID = MAX_SUPPLY - LEGENDARY_SUPPLY + 1;

    /// @notice Legendary auctions begin each time a multiple of these many gobblers have been minted from goo.
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
        // Last randomness obtained from the rand provider.
        uint64 randomSeed;
        // Next reveal cannot happen before this timestamp.
        uint64 nextRevealTimestamp;
        // Id of latest gobbler which has been revealed so far.
        uint56 lastRevealedId;
        // Remaining gobblers to be revealed with the current seed.
        uint56 toBeRevealed;
        // Whether we are waiting to receive a seed from Chainlink.
        bool waitingForSeed;
    }

    /// @notice Data about the current state of gobbler reveals.
    GobblerRevealsData public gobblerRevealsData;

    /*//////////////////////////////////////////////////////////////
                            GOBBLED ART STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps gobbler ids to NFT contracts and their ids to the # of those NFT ids gobbled by the gobbler.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public getCopiesOfArtGobbledByGobbler;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);

    event GobblerClaimed(address indexed user, uint256 indexed gobblerId);
    event GobblerPurchased(address indexed user, uint256 indexed gobblerId, uint256 price);
    event LegendaryGobblerMinted(address indexed user, uint256 indexed gobblerId, uint256[] burnedGobblerIds);
    event ReservedGobblersMinted(address indexed user, uint256 lastMintedGobblerId, uint256 numGobblersEach);

    event RandomnessFulfilled(uint256 randomness);
    event RandomnessRequested(address indexed user, uint256 toBeRevealed);
    event RandProviderUpgraded(address indexed user, RandProvider indexed newRandProvider);

    event GobblersRevealed(address indexed user, uint256 numGobblers, uint256 lastRevealedId);

    event ArtGobbled(address indexed user, uint256 indexed gobblerId, address indexed nft, uint256 id);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidProof();
    error AlreadyClaimed();
    error MintStartPending();

    error SeedPending();
    error RevealsPending();
    error RequestTooEarly();
    error ZeroToBeRevealed();
    error NotRandProvider();

    error ReserveImbalance();

    error Cannibalism();
    error OwnerMismatch(address owner);

    error NoRemainingLegendaryGobblers();
    error CannotBurnLegendary(uint256 gobblerId);
    error InsufficientGobblerAmount(uint256 cost);
    error LegendaryAuctionNotStarted(uint256 gobblersLeft);

    error PriceExceededMax(uint256 currentPrice);

    error NotEnoughRemainingToBeRevealed(uint256 totalRemainingToBeRevealed);

    error UnauthorizedCaller(address caller);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets VRGDA parameters, mint config, relevant addresses, and URIs.
    /// @param _merkleRoot Merkle root of mint mintlist.
    /// @param _mintStart Timestamp for the start of the VRGDA mint.
    /// @param _goo Address of the Goo contract.
    /// @param _team Address of the team reserve.
    /// @param _community Address of the community reserve.
    /// @param _randProvider Address of the randomness provider.
    /// @param _baseUri Base URI for revealed gobblers.
    /// @param _unrevealedUri URI for unrevealed gobblers.
    constructor(
        // Mint config:
        bytes32 _merkleRoot,
        uint256 _mintStart,
        // Addresses:
        Goo _goo,
        Pages _pages,
        address _team,
        address _community,
        RandProvider _randProvider,
        // URIs:
        string memory _baseUri,
        string memory _unrevealedUri
    )
        GobblersERC721("Art Gobblers", "GOBBLER")
        LogisticVRGDA(
            69.42e18, // Target price.
            0.31e18, // Price decay percent.
            // Max gobblers mintable via VRGDA.
            toWadUnsafe(MAX_MINTABLE),
            0.0023e18 // Time scale.
        )
        Owned(msg.sender)
    {
        mintStart = _mintStart;
        merkleRoot = _merkleRoot;

        goo = _goo;
        pages = _pages;
        team = _team;
        community = _community;
        randProvider = _randProvider;

        BASE_URI = _baseUri;
        UNREVEALED_URI = _unrevealedUri;

        // Set the starting price for the first legendary gobbler auction.
        legendaryGobblerAuctionData.startPrice = uint128(LEGENDARY_GOBBLER_INITIAL_START_PRICE);

        // Reveal for initial mint must wait a day from the start of the mint.
        gobblerRevealsData.nextRevealTimestamp = uint64(_mintStart + 1 days);
    }

    /*//////////////////////////////////////////////////////////////
                          MINTLIST CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim from mintlist, using a merkle proof.
    /// @dev Function does not directly enforce the MINTLIST_SUPPLY limit for gas efficiency. The
    /// limit is enforced during the creation of the merkle proof, which will be shared publicly.
    /// @param proof Merkle proof to verify the sender is mintlisted.
    /// @return gobblerId The id of the gobbler that was claimed.
    function claimGobbler(bytes32[] calldata proof) external returns (uint256 gobblerId) {
        // If minting has not yet begun, revert.
        if (mintStart > block.timestamp) revert MintStartPending();

        // If the user has already claimed, revert.
        if (hasClaimedMintlistGobbler[msg.sender]) revert AlreadyClaimed();

        // If the user's proof is invalid, revert.
        if (!MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();

        hasClaimedMintlistGobbler[msg.sender] = true;

        unchecked {
            // Overflow should be impossible due to supply cap of 10,000.
            emit GobblerClaimed(msg.sender, gobblerId = ++currentNonLegendaryId);
        }

        _mint(msg.sender, gobblerId);
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a gobbler, paying with goo.
    /// @param maxPrice Maximum price to pay to mint the gobbler.
    /// @param useVirtualBalance Whether the cost is paid from the
    /// user's virtual goo balance, or from their ERC20 goo balance.
    /// @return gobblerId The id of the gobbler that was minted.
    function mintFromGoo(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 gobblerId) {
        // No need to check if we're at MAX_MINTABLE,
        // gobblerPrice() will revert once we reach it due to its
        // logistic nature. It will also revert prior to the mint start.
        uint256 currentPrice = gobblerPrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        // Decrement the user's goo balance by the current
        // price, either from virtual balance or ERC20 balance.
        useVirtualBalance
            ? updateUserGooBalance(msg.sender, currentPrice, GooBalanceUpdateType.DECREASE)
            : goo.burnForGobblers(msg.sender, currentPrice);

        unchecked {
            ++numMintedFromGoo; // Overflow should be impossible due to the supply cap.

            emit GobblerPurchased(msg.sender, gobblerId = ++currentNonLegendaryId, currentPrice);
        }

        _mint(msg.sender, gobblerId);
    }

    /// @notice Gobbler pricing in terms of goo.
    /// @dev Will revert if called before minting starts
    /// or after all gobblers have been minted via VRGDA.
    /// @return Current price of a gobbler in terms of goo.
    function gobblerPrice() public view returns (uint256) {
        // We need checked math here to cause underflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), numMintedFromGoo);
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

        if (gobblerIds.length < cost) revert InsufficientGobblerAmount(cost);

        // Overflow should not occur in here, as most math is on emission multiples, which are inherently small.
        unchecked {
            uint256 burnedMultipleTotal; // The legendary's emissionMultiple will be 2x the sum of the gobblers burned.

            /*//////////////////////////////////////////////////////////////
                                    BATCH BURN LOGIC
            //////////////////////////////////////////////////////////////*/

            uint256 id; // Storing outside the loop saves ~7 gas per iteration.

            for (uint256 i = 0; i < cost; ++i) {
                id = gobblerIds[i];

                if (id >= FIRST_LEGENDARY_GOBBLER_ID) revert CannotBurnLegendary(id);

                require(getGobblerData[id].owner == msg.sender, "WRONG_FROM");

                burnedMultipleTotal += getGobblerData[id].emissionMultiple;

                emit Transfer(msg.sender, getGobblerData[id].owner = address(0), id);
            }

            /*//////////////////////////////////////////////////////////////
                                 LEGENDARY MINTING LOGIC
            //////////////////////////////////////////////////////////////*/

            // The legendary's emissionMultiple is 2x the sum of the multiples of the gobblers burned.
            getGobblerData[gobblerId].emissionMultiple = uint32(burnedMultipleTotal * 2);

            // Update the user's user data struct in one big batch. We add burnedMultipleTotal to their
            // emission multiple (not burnedMultipleTotal * 2) to account for the standard gobblers that
            // were burned and hence should have their multiples subtracted from the user's total multiple.
            getUserData[msg.sender].lastBalance = uint128(gooBalance(msg.sender)); // Checkpoint balance.
            getUserData[msg.sender].lastTimestamp = uint64(block.timestamp); // Store time alongside it.
            getUserData[msg.sender].emissionMultiple += uint32(burnedMultipleTotal); // Update multiple.
            // We subtract the amount of gobblers burned, and then add 1 to factor in the new legendary.
            getUserData[msg.sender].gobblersOwned = uint32(getUserData[msg.sender].gobblersOwned - cost + 1);

            // New start price is the max of LEGENDARY_GOBBLER_INITIAL_START_PRICE and cost * 2.
            legendaryGobblerAuctionData.startPrice = uint120(
                cost <= LEGENDARY_GOBBLER_INITIAL_START_PRICE / 2 ? LEGENDARY_GOBBLER_INITIAL_START_PRICE : cost * 2
            );
            legendaryGobblerAuctionData.numSold += 1; // Increment the # of legendaries sold.

            // If gobblerIds has 1,000 elements this should cost around ~270,000 gas.
            emit LegendaryGobblerMinted(msg.sender, gobblerId, gobblerIds[:cost]);

            _mint(msg.sender, gobblerId);
        }
    }

    /// @notice Calculate the legendary gobbler price in terms of gobblers, according to a linear decay function.
    /// @dev The price of a legendary gobbler decays as gobblers are minted. The first legendary auction begins when
    /// 1 LEGENDARY_AUCTION_INTERVAL worth of gobblers are minted, and the price decays linearly while the next interval of
    /// gobblers are minted. Every time an additional interval is minted, a new auction begins until all legendaries have been sold.
    /// @return price of legendary gobbler, in terms of gobblers.
    function legendaryGobblerPrice() public view returns (uint256) {
        // Retrieve and cache various auction parameters and variables.
        uint256 startPrice = legendaryGobblerAuctionData.startPrice;
        uint256 numSold = legendaryGobblerAuctionData.numSold;
        uint256 mintedFromGoo = numMintedFromGoo;

        unchecked {
            // The number of gobblers minted at the start of the auction is computed by multiplying the # of
            // intervals that must pass before the next auction begins by the number of gobblers in each interval.
            uint256 numMintedAtStart = (numSold + 1) * LEGENDARY_AUCTION_INTERVAL;

            // If not enough gobblers have been minted to start the auction yet, return how many need to be minted.
            if (numMintedAtStart > mintedFromGoo) revert LegendaryAuctionNotStarted(numMintedAtStart - mintedFromGoo);

            // Compute how many gobblers were minted since the auction began.
            uint256 numMintedSinceStart = numMintedFromGoo - numMintedAtStart;

            // prettier-ignore
            // If we've minted the full interval or beyond it, the price has decayed to 0.
            if (numMintedSinceStart >= LEGENDARY_AUCTION_INTERVAL) return 0;
            // Otherwise decay the price linearly based on what fraction of the interval has been minted.
            else return FixedPointMathLib.unsafeDivUp(startPrice * (LEGENDARY_AUCTION_INTERVAL - numMintedSinceStart), LEGENDARY_AUCTION_INTERVAL);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            RANDOMNESS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Request a new random seed for revealing gobblers.
    /// @dev Can only be called every 24 hours at the earliest.
    function requestRandomSeed() external returns (bytes32) {
        uint256 nextRevealTimestamp = gobblerRevealsData.nextRevealTimestamp;

        // A new random seed cannot be requested before the next reveal timestamp.
        if (block.timestamp < nextRevealTimestamp) revert RequestTooEarly();

        // A random seed can only be requested when all gobblers from the previous seed have been revealed.
        // This prevents a user from requesting additional randomness in hopes of a more favorable outcome.
        if (gobblerRevealsData.toBeRevealed != 0) revert RevealsPending();

        unchecked {
            // Prevent revealing while we wait for the seed.
            gobblerRevealsData.waitingForSeed = true;

            // Compute the number of gobblers to be revealed with the seed.
            uint256 toBeRevealed = currentNonLegendaryId - gobblerRevealsData.lastRevealedId;

            // Ensure that there are more than 0 gobblers to be revealed,
            // otherwise the contract could waste LINK revealing nothing.
            if (toBeRevealed == 0) revert ZeroToBeRevealed();

            // Lock in the number of gobblers to be revealed from seed.
            gobblerRevealsData.toBeRevealed = uint56(toBeRevealed);

            // We want at most one batch of reveals every 24 hours.
            // Timestamp overflow is impossible on human timescales.
            gobblerRevealsData.nextRevealTimestamp = uint64(nextRevealTimestamp + 1 days);

            emit RandomnessRequested(msg.sender, toBeRevealed);
        }

        // Call out to the randomness provider.
        return randProvider.requestRandomBytes();
    }

    /// @notice Callback from rand provider. Sets randomSeed. Can only be called by the rand provider.
    /// @param randomness The 256 bits of verifiable randomness provided by the rand provider.
    function acceptRandomSeed(bytes32, uint256 randomness) external {
        // The caller must be the randomness provider, revert in the case it's not.
        if (msg.sender != address(randProvider)) revert NotRandProvider();

        // The unchecked cast to uint64 is equivalent to moduloing the randomness by 2**64.
        gobblerRevealsData.randomSeed = uint64(randomness); // 64 bits of randomness is plenty.

        gobblerRevealsData.waitingForSeed = false; // We have the seed now, open up reveals.

        emit RandomnessFulfilled(randomness);
    }

    /// @notice Upgrade the rand provider contract. Useful if current VRF is sunset.
    /// @param newRandProvider The new randomness provider contract address.
    function upgradeRandProvider(RandProvider newRandProvider) external onlyOwner {
        // Revert if waiting for seed, so we don't interrupt requests in flight.
        if (gobblerRevealsData.waitingForSeed) revert SeedPending();

        randProvider = newRandProvider; // Update the randomness provider.

        emit RandProviderUpgraded(msg.sender, newRandProvider);
    }

    /*//////////////////////////////////////////////////////////////
                          GOBBLER REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Knuth shuffle to progressively reveal
    /// new gobblers using entropy from a random seed.
    /// @param numGobblers The number of gobblers to reveal.
    function revealGobblers(uint256 numGobblers) external {
        uint256 randomSeed = gobblerRevealsData.randomSeed;

        uint256 lastRevealedId = gobblerRevealsData.lastRevealedId;

        uint256 totalRemainingToBeRevealed = gobblerRevealsData.toBeRevealed;

        // Can't reveal if we're still waiting for a new seed.
        if (gobblerRevealsData.waitingForSeed) revert SeedPending();

        // Can't reveal more gobblers than are currently remaining to be revealed with the seed.
        if (numGobblers > totalRemainingToBeRevealed) revert NotEnoughRemainingToBeRevealed(totalRemainingToBeRevealed);

        // Implements a Knuth shuffle. If something in
        // here can overflow, we've got bigger problems.
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
                uint64 swapIndex = getGobblerData[swapId].idx == 0
                    ? uint64(swapId) // Hasn't been shuffled before.
                    : getGobblerData[swapId].idx; // Shuffled before.

                // Get the owner of the current id.
                address currentIdOwner = getGobblerData[currentId].owner;

                // Get the index of the current id.
                uint64 currentIndex = getGobblerData[currentId].idx == 0
                    ? uint64(currentId) // Hasn't been shuffled before.
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
                    newCurrentIdMultiple := sub(sub(sub(
                        newCurrentIdMultiple,
                        lt(swapIndex, 7964)),
                        lt(swapIndex, 5673)),
                        lt(swapIndex, 3055)
                    )
                }

                // Swap the index and multiple of the current id.
                getGobblerData[currentId].idx = swapIndex;
                getGobblerData[currentId].emissionMultiple = uint32(newCurrentIdMultiple);

                // Swap the index of the swap id.
                getGobblerData[swapId].idx = currentIndex;

                /*//////////////////////////////////////////////////////////////
                                   UPDATE CURRENT ID MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Update the user data for the owner of the current id.
                getUserData[currentIdOwner].lastBalance = uint128(gooBalance(currentIdOwner));
                getUserData[currentIdOwner].lastTimestamp = uint64(block.timestamp);
                getUserData[currentIdOwner].emissionMultiple += uint32(newCurrentIdMultiple);

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

            // Update all relevant reveal state.
            gobblerRevealsData.randomSeed = uint64(randomSeed);
            gobblerRevealsData.lastRevealedId = uint56(lastRevealedId);
            gobblerRevealsData.toBeRevealed = uint56(totalRemainingToBeRevealed - numGobblers);

            emit GobblersRevealed(msg.sender, numGobblers, lastRevealedId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a token's URI if it has been minted.
    /// @param gobblerId The id of the token to get the URI for.
    function tokenURI(uint256 gobblerId) public view virtual override returns (string memory) {
        // Between 0 and lastRevealed are revealed normal gobblers.
        if (gobblerId <= gobblerRevealsData.lastRevealedId) {
            if (gobblerId == 0) revert("NOT_MINTED"); // 0 is not a valid id for Art Gobblers.

            return string.concat(BASE_URI, uint256(getGobblerData[gobblerId].idx).toString());
        }

        // Between lastRevealed + 1 and currentNonLegendaryId are minted but not revealed.
        if (gobblerId <= currentNonLegendaryId) return UNREVEALED_URI;

        // Between currentNonLegendaryId and FIRST_LEGENDARY_GOBBLER_ID are unminted.
        if (gobblerId < FIRST_LEGENDARY_GOBBLER_ID) revert("NOT_MINTED");

        // Between FIRST_LEGENDARY_GOBBLER_ID and FIRST_LEGENDARY_GOBBLER_ID + numSold are minted legendaries.
        if (gobblerId < FIRST_LEGENDARY_GOBBLER_ID + legendaryGobblerAuctionData.numSold)
            return string.concat(BASE_URI, gobblerId.toString());

        revert("NOT_MINTED"); // Unminted legendaries and invalid token ids.
    }

    /*//////////////////////////////////////////////////////////////
                            GOBBLE ART LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Feed a gobbler a work of art.
    /// @param gobblerId The gobbler to feed the work of art.
    /// @param nft The ERC721 or ERC1155 contract of the work of art.
    /// @param id The id of the work of art.
    /// @param isERC1155 Whether the work of art is an ERC1155 token.
    function gobble(
        uint256 gobblerId,
        address nft,
        uint256 id,
        bool isERC1155
    ) external {
        // Get the owner of the gobbler to feed.
        address owner = getGobblerData[gobblerId].owner;

        // The caller must own the gobbler they're feeding.
        if (owner != msg.sender) revert OwnerMismatch(owner);

        // Gobblers have taken a vow not to eat other gobblers.
        if (nft == address(this)) revert Cannibalism();

        unchecked {
            // Increment the # of copies gobbled by the gobbler. Unchecked is
            // safe, as an NFT can't have more than type(uint256).max copies.
            ++getCopiesOfArtGobbledByGobbler[gobblerId][nft][id];
        }

        emit ArtGobbled(msg.sender, gobblerId, nft, id);

        isERC1155
            ? ERC1155(nft).safeTransferFrom(msg.sender, address(this), id, 1, "")
            : ERC721(nft).transferFrom(msg.sender, address(this), id);
    }

    /*//////////////////////////////////////////////////////////////
                                GOO LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate a user's virtual goo balance.
    /// @param user The user to query balance for.
    function gooBalance(address user) public view returns (uint256) {
        // Compute the user's virtual goo balance by leveraging LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            getUserData[user].emissionMultiple,
            getUserData[user].lastBalance,
            uint(toDaysWadUnsafe(block.timestamp - getUserData[user].lastTimestamp))
        );
    }

    /// @notice Add goo to your emission balance,
    /// burning the corresponding ERC20 balance.
    /// @param gooAmount The amount of goo to add.
    function addGoo(uint256 gooAmount) external {
        // Burn goo being added to gobbler.
        goo.burnForGobblers(msg.sender, gooAmount);

        // Increase msg.sender's virtual goo balance.
        updateUserGooBalance(msg.sender, gooAmount, GooBalanceUpdateType.INCREASE);
    }

    /// @notice Remove goo from your emission balance, and
    /// add the corresponding amount to your ERC20 balance.
    /// @param gooAmount The amount of goo to remove.
    function removeGoo(uint256 gooAmount) external {
        // Decrease msg.sender's virtual goo balance.
        updateUserGooBalance(msg.sender, gooAmount, GooBalanceUpdateType.DECREASE);

        // Mint the corresponding amount of ERC20 goo.
        goo.mintForGobblers(msg.sender, gooAmount);
    }

    /// @notice Burn an amount of a user's virtual goo balance. Only callable
    /// by the Pages contract to enable purchasing pages with virtual balance.
    /// @param user The user whose virtual goo balance we should burn from.
    /// @param gooAmount The amount of goo to burn from the user's virtual balance.
    function burnGooForPages(address user, uint256 gooAmount) external {
        // The caller must be the Pages contract, revert otherwise.
        if (msg.sender != address(pages)) revert UnauthorizedCaller(msg.sender);

        // Burn the requested amount of goo from the user's virtual goo balance.
        // Will revert if the user doesn't have enough goo in their virtual balance.
        updateUserGooBalance(user, gooAmount, GooBalanceUpdateType.DECREASE);
    }

    /// @dev An enum for representing whether to
    /// increase or decrease a user's goo balance.
    enum GooBalanceUpdateType {
        INCREASE,
        DECREASE
    }

    /// @notice Update a user's virtual goo balance.
    /// @param user The user whose virtual goo balance we should update.
    /// @param gooAmount The amount of goo to update the user's virtual balance by.
    /// @param updateType Whether to increase or decrease the user's balance by gooAmount.
    function updateUserGooBalance(
        address user,
        uint256 gooAmount,
        GooBalanceUpdateType updateType
    ) internal {
        // Will revert due to underflow if we're decreasing by more than the user's current balance.
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance = updateType == GooBalanceUpdateType.INCREASE
            ? gooBalance(user) + gooAmount
            : gooBalance(user) - gooAmount;

        // Snapshot the user's new goo balance with the current timestamp.
        getUserData[user].lastBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint64(block.timestamp);

        emit GooBalanceUpdated(user, updatedBalance);
    }

    /*//////////////////////////////////////////////////////////////
                     RESERVED GOBBLERS MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of gobblers to the reserves.
    /// @param numGobblersEach The number of gobblers to mint to each reserve.
    /// @dev Gobblers minted to reserves cannot comprise more than 20% of the sum of
    /// the supply of goo minted gobblers and the supply of gobblers minted to reserves.
    function mintReservedGobblers(uint256 numGobblersEach) external returns (uint256 lastMintedGobblerId) {
        unchecked {
            // Optimistically increment numMintedForReserves, may be reverted below. Overflow in this
            // calculation is possible but numGobblersEach would have to be so large that it would cause the
            // loop in _batchMint to run out of gas quickly. Shift left by 1 is equivalent to multiplying by 2.
            uint256 newNumMintedForReserves = numMintedForReserves += (numGobblersEach << 1);

            // Ensure that after this mint gobblers minted to reserves won't comprise more than 20% of
            // the sum of the supply of goo minted gobblers and the supply of gobblers minted to reserves.
            if (newNumMintedForReserves > (numMintedFromGoo + newNumMintedForReserves) / 5) revert ReserveImbalance();
        }

        // Mint numGobblersEach gobblers to both the team and community reserve.
        lastMintedGobblerId = _batchMint(team, numGobblersEach, currentNonLegendaryId);
        lastMintedGobblerId = _batchMint(community, numGobblersEach, lastMintedGobblerId);

        currentNonLegendaryId = uint128(lastMintedGobblerId); // Set currentNonLegendaryId.

        emit ReservedGobblersMinted(msg.sender, lastMintedGobblerId, numGobblersEach);
    }

    /*//////////////////////////////////////////////////////////////
                          CONVENIENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Convenience function to get emissionMultiple for a gobbler.
    /// @param gobblerId The gobbler to get emissionMultiple for.
    function getGobblerEmissionMultiple(uint256 gobblerId) external view returns (uint256) {
        return getGobblerData[gobblerId].emissionMultiple;
    }

    /// @notice Convenience function to get emissionMultiple for a user.
    /// @param user The user to get emissionMultiple for.
    function getUserEmissionMultiple(address user) external view returns (uint256) {
        return getUserData[user].emissionMultiple;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == getGobblerData[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        delete getApproved[id];

        getGobblerData[id].owner = to;

        unchecked {
            uint32 emissionMultiple = getGobblerData[id].emissionMultiple; // Caching saves gas.

            // We update their last balance before updating their emission multiple to avoid
            // penalizing them by retroactively applying their new (lower) emission multiple.
            getUserData[from].lastBalance = uint128(gooBalance(from));
            getUserData[from].lastTimestamp = uint64(block.timestamp);
            getUserData[from].emissionMultiple -= emissionMultiple;
            getUserData[from].gobblersOwned -= 1;

            // We update their last balance before updating their emission multiple to avoid
            // overpaying them by retroactively applying their new (higher) emission multiple.
            getUserData[to].lastBalance = uint128(gooBalance(to));
            getUserData[to].lastTimestamp = uint64(block.timestamp);
            getUserData[to].emissionMultiple += emissionMultiple;
            getUserData[to].gobblersOwned += 1;
        }

        emit Transfer(from, to, id);
    }
}
