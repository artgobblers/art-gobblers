// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";

import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";

import {wadDiv} from "./utils/SignedWadMath.sol";
import {LogisticVRGDA} from "./utils/LogisticVRGDA.sol";

import {Goop} from "./Goop.sol";
import {Pages} from "./Pages.sol";

// TODO: UNCHECKED
// TODO: I believe gas went up in commit T cuz forge was underestimating earlier? need to double check
// TODO: Make sure we're ok with people being able to mint one more than the max (cuz we start at 0)
// TODO: check everything is being packed properly with forge inspect
// TODO: ensure it was safe that we removed the max supply checks
// TODO: can we make mint start constant by setting merkle root at deploy uwu would save sload

/// @title Art Gobblers NFT (GBLR)
/// @notice Art Gobblers scan the cosmos in search of art producing life.
contract ArtGobblers is
    ERC721("Art Gobblers", "GBLR"),
    Auth(msg.sender, Authority(address(0))),
    VRFConsumerBase,
    LogisticVRGDA
{
    using Strings for uint256;
    using FixedPointMathLib for uint256;

    /// -------------------------
    /// ------- Addresses -------
    /// -------------------------

    Goop public immutable goop;

    Pages public immutable pages;

    /// --------------------------
    /// ---- Supply Constants ----
    /// --------------------------

    /// @notice Maximum number of mintable tokens.
    uint256 private constant MAX_SUPPLY = 10000;

    /// @notice Maximum amount of gobblers mintable via whitelist.
    uint256 private constant WHITELIST_SUPPLY = 2000;

    /// @notice Maximum amount of mintable legendary gobblers.
    uint256 private constant LEGENDARY_SUPPLY = 10;

    /// @notice Maximum number of tokens publicly mintable via goop.
    uint256 private MAX_MINTABLE_WITH_GOOP = MAX_SUPPLY - WHITELIST_SUPPLY - LEGENDARY_SUPPLY;

    /// ---------------------------
    /// ---- URI Configuration ----
    /// ---------------------------

    /// @notice Base URI for minted gobblers.
    string public BASE_URI;

    /// @notice URI for gobblers that have yet to be revealed.
    string public UNREVEALED_URI;

    /// ---------------------------
    /// ---- VRF Configuration ----
    /// ---------------------------

    bytes32 internal immutable chainlinkKeyHash;

    uint256 internal immutable chainlinkFee;

    /// -------------------------
    /// ---- Whitelist State ----
    /// -------------------------

    /// @notice Merkle root of mint whitelist.
    bytes32 public merkleRoot;

    /// @notice Mapping to keep track of which addresses have claimed from whitelist.
    mapping(address => bool) public claimedWhitelist;

    /// ---------------------------
    /// ---- VRGDA Input State ----
    /// ---------------------------

    /// @notice Timestamp for the start of the mint.
    uint128 public mintStart;

    /// @notice Number of gobblers minted from goop.
    uint128 public numMintedFromGoop;

    /// -------------------------
    /// ---- Attribute State ----
    /// -------------------------

    /// @notice Struct holding gobbler attributes.
    struct GobblerAttributes {
        /// @notice Index of token after shuffle.
        uint128 idx;
        /// @notice Base issuance rate for goop.
        uint64 baseRate;
        /// @notice Multiple on goop issuance.
        uint64 stakingMultiple;
    }

    /// @notice Maps gobbler ids to their attributes.
    mapping(uint256 => GobblerAttributes) public attributeList;

    /// ----------------------
    /// ---- Reveal State ----
    /// ----------------------

    // TODO: investigate pack

    /// @notice Random seed obtained from VRF.
    uint256 public randomSeed;

    /// @notice Index of last token that has been revealed.
    uint128 public lastRevealedIndex;

    /// @notice Remaining gobblers to be assigned from seed.
    uint128 public gobblersToBeAssigned;

    /// --------------------------
    /// ----- Staking State  -----
    /// --------------------------

    /// @notice Struct holding info required for goop staking reward calculation.
    struct StakingInfo {
        /// @notice Balance at time of last deposit or withdrawal.
        uint128 lastBalance;
        /// @notice Timestamp of last deposit or withdrawal.
        uint128 lastTimestamp;
    }

    /// @notice Mapping from tokenId to staking info.
    mapping(uint256 => StakingInfo) public stakingInfoMap;

    /// -------------------------------
    /// ----- Legendary Gobblers  -----
    /// -------------------------------

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
        uint16 currentLegendaryId;
    }

    /// @notice Data about the current legendary gobbler auction.
    LegendaryGobblerAuctionData public legendaryGobblerAuctionData;

    /// ------------------------------
    /// ----- Standard Gobblers  -----
    /// ------------------------------

    /// @notice Id of last minted non legendary token.
    uint256 internal currentNonLegendaryId;

    /// ----------------------------
    /// -------- Art Feeding  ------
    /// ----------------------------

    /// @notice Mapping from page ids to gobbler ids they were fed to.
    mapping(uint256 => uint256) public pageIdToGobblerId;

    /// ----------------------
    /// -------- Events ------
    /// ----------------------

    /// @notice Merkle root was set.
    event MerkleRootSet(bytes32 merkleRoot);

    /// @notice Legendary gobbler was minted.
    event LegendaryGobblerMint(uint256 tokenId);

    /// ---------------------
    /// ------- Errors ------
    /// ---------------------

    error Unauthorized();

    error InsufficientGobblerBalance();

    error NoRemainingLegendaryGobblers();

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        string memory _baseUri
    )
        VRFConsumerBase(vrfCoordinator, linkToken)
        LogisticVRGDA(
            // Logistic scale. We multiply by 2x (as a wad)
            // to account for the subtracted initial value:
            int256(MAX_MINTABLE_WITH_GOOP + 1) * 2e18,
            // Time scale:
            wadDiv(1e18, 60e18),
            0, // Time shift.
            69e18, // Initial price.
            0.25e18 // Per period price decrease.
        )
    {
        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;
        goop = new Goop(address(this));
        pages = new Pages(address(goop), msg.sender);

        goop.setPages(address(pages));

        BASE_URI = _baseUri;

        // Start price for legendary gobblers is 100 gobblers.
        legendaryGobblerAuctionData.currentLegendaryGobblerStartPrice = 100;

        // First legendary gobbler auction starts 30 days after contract deploy.
        legendaryGobblerAuctionData.currentLegendaryGobblerAuctionStart = uint120(block.timestamp + 30 days);

        // Current legendary id starts at beginning of legendary id space.
        legendaryGobblerAuctionData.currentLegendaryId = uint16(LEGENDARY_GOBBLER_ID_START);
    }

    /// @notice Set merkle root for minting whitelist, can only be done once.
    function setMerkleRoot(bytes32 _merkleRoot) public requiresAuth {
        // Don't allow setting the merkle root twice.
        if (merkleRoot != 0) revert Unauthorized();

        merkleRoot = _merkleRoot;

        mintStart = uint128(block.timestamp);

        pages.setMintStart(block.timestamp);

        emit MerkleRootSet(_merkleRoot);
    }

    /// @notice Mint from whitelist, using a merkle proof.
    function mintFromWhitelist(bytes32[] calldata _merkleProof) public {
        bytes32 root = merkleRoot;

        if (root == 0 || claimedWhitelist[msg.sender]) revert Unauthorized();

        if (!MerkleProof.verify(_merkleProof, root, keccak256(abi.encodePacked(msg.sender)))) revert Unauthorized();

        claimedWhitelist[msg.sender] = true;

        mintGobbler(msg.sender);

        pages.mintByAuth(msg.sender); // Whitelisted users also get a free page.
    }

    /// @notice Mint from goop, burning the cost.
    function mintFromGoop() public {
        // No need to check supply cap, gobblerPrice()
        // will revert due to overflow if we reach it.
        goop.burnForGobblers(msg.sender, gobblerPrice());

        mintGobbler(msg.sender);

        unchecked {
            numMintedFromGoop++;
        }
    }

    /// @notice Gobbler pricing in terms of goop.
    /// @dev Can revert due to overflow if buying far
    /// too early/late or beyond the chosen supply cap.
    function gobblerPrice() public view returns (uint256) {
        return getPrice(block.timestamp - mintStart, numMintedFromGoop);
    }

    function mintGobbler(address mintAddress) internal {
        // Only arithmetic done is the counter increment.
        unchecked {
            uint256 newId = ++currentNonLegendaryId;

            _mint(mintAddress, newId);

            // Start generating goop from mint time.
            stakingInfoMap[newId].lastTimestamp = uint128(block.timestamp);
        }
    }

    /// @notice Mint a legendary gobbler by burning multiple standard gobblers.
    function mintLegendaryGobbler(uint256[] calldata gobblerIds) public {
        uint256 legendaryId = legendaryGobblerAuctionData.currentLegendaryId;

        // When legendary id surpasses max supply, we've minted all 10 legendary gobblers:
        if (legendaryId >= MAX_SUPPLY) revert NoRemainingLegendaryGobblers();

        // This will revert if the auction hasn't started yet, no need to check here as well.
        uint256 cost = legendaryGobblerPrice();

        if (gobblerIds.length != cost) revert InsufficientGobblerBalance();

        // Burn the gobblers provided as tribute.
        unchecked {
            for (uint256 i = 0; i < gobblerIds.length; i++) {
                if (ownerOf[gobblerIds[i]] != msg.sender) revert Unauthorized();

                _burn(gobblerIds[i]); // TODO: can inline this and skip ownership check
            }
        }

        uint256 newId = (legendaryGobblerAuctionData.currentLegendaryId = uint16(legendaryId + 1));

        // Mint the legendary gobbler.
        _mint(msg.sender, newId);

        // It gets a special event.
        emit LegendaryGobblerMint(newId);

        // Start a new auction, 30 days after the previous start.
        legendaryGobblerAuctionData.currentLegendaryGobblerAuctionStart += 30 days;

        // New start price is max of (100, prev_cost*2).
        legendaryGobblerAuctionData.currentLegendaryGobblerStartPrice = uint120(cost < 50 ? 100 : cost << 1); // Shift left by 1 is like multiplication by 2.
    }

    /// @notice Calculate the legendary gobbler price in terms of gobblers, according to linear decay function.
    /// @dev Reverts due to underflow if the auction has not yet begun. This is intended behavior and helps save gas.
    function legendaryGobblerPrice() public view returns (uint256) {
        uint256 daysSinceStart = (block.timestamp - legendaryGobblerAuctionData.currentLegendaryGobblerAuctionStart) /
            1 days;

        // If more than 30 days have passed, legendary gobbler is free, else, decay linearly over 30 days.
        return
            daysSinceStart >= 30
                ? 0
                : (legendaryGobblerAuctionData.currentLegendaryGobblerStartPrice * (30 - daysSinceStart)) / 30;
    }

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

    /// @notice Knuth shuffle to progressively reveal gobblers using entropy from random seed.
    function revealGobblers(uint256 numGobblers) public {
        // Can't reveal more gobblers than were available when seed was generated.
        if (numGobblers > gobblersToBeAssigned) revert Unauthorized();

        uint256 currentRandomSeed = randomSeed;

        // @audit TODO return to this. Particularly check randomness is updated each time, what is idx doing, etc.

        // Implements a Knuth shuffle. If something in
        // here can overflow we've got bigger problems.
        unchecked {
            for (uint256 i = 0; i < numGobblers; i++) {
                // Number of slots that have not been assigned.
                uint256 remainingSlots = LEGENDARY_GOBBLER_ID_START - lastRevealedIndex;

                // Randomly pick distance for swap.
                uint256 distance = randomSeed % remainingSlots;

                // Select swap slot, adding distance to next reveal slot.
                uint256 swapSlot = lastRevealedIndex + 1 + distance;

                // If index in swap slot is 0, that means slot has never been touched, thus, it has the default value, which is the slot index.
                uint128 swapIndex = attributeList[swapSlot].idx == 0 ? uint128(swapSlot) : attributeList[swapSlot].idx;

                // Current slot is consecutive to last reveal.
                uint256 currentSlot = lastRevealedIndex + 1;

                // Again, we derive index based on value:
                uint128 currentIndex = attributeList[currentSlot].idx == 0
                    ? uint128(currentSlot)
                    : attributeList[currentSlot].idx;

                // Swap indices.
                attributeList[currentSlot].idx = swapIndex;
                attributeList[swapSlot].idx = currentIndex;

                // Select random attributes for current slot:
                currentRandomSeed = uint256(keccak256(abi.encodePacked(currentRandomSeed)));
                attributeList[currentSlot].baseRate = uint64(currentRandomSeed % 4) + 1;
                attributeList[currentSlot].stakingMultiple = uint64(currentRandomSeed % 128) + 1;
            }
        }

        // Update state all at once.
        randomSeed = currentRandomSeed;
        lastRevealedIndex += uint128(numGobblers);
        gobblersToBeAssigned -= uint128(numGobblers);
    }

    /// @notice Returns a token's URI if it has been minted.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // Between 0 and lastRevealedIndex are revealed normal gobblers.
        if (tokenId <= lastRevealedIndex) {
            // 0 is not a valid id:
            if (tokenId == 0) return "";

            return string(abi.encodePacked(BASE_URI, uint256(attributeList[tokenId].idx).toString()));
        }
        // Between lastRevealedIndex + 1 and currentNonLegendaryId are minted but not revealed.
        if (tokenId <= currentNonLegendaryId) return UNREVEALED_URI;

        // Between currentNonLegendaryId and  LEGENDARY_GOBBLER_ID_START are unminted.
        if (tokenId <= LEGENDARY_GOBBLER_ID_START) return "";

        // Between LEGENDARY_GOBBLER_ID_START and currentLegendaryId are minted legendaries.
        if (tokenId <= legendaryGobblerAuctionData.currentLegendaryId)
            return string(abi.encodePacked(BASE_URI, tokenId.toString()));

        return ""; // Unminted legendaries and invalid token ids.
    }

    /// @notice Convenience function to get staking multiple for a gobbler.
    function getStakingMultiple(uint256 tokenId) public view returns (uint256 multiple) {
        multiple = attributeList[tokenId].stakingMultiple;
    }

    /// @notice Convenience function to get the base issuance rate for a gobbler.
    function getBaseRate(uint256 tokenId) public view returns (uint256 rate) {
        rate = attributeList[tokenId].baseRate;
    }

    /// @notice Feed a gobbler a page.
    function feedArt(uint256 gobblerId, uint256 pageId) public {
        // The page must be drawn on and the caller must own this gobbler:
        if (!pages.isDrawn(pageId) || ownerOf[gobblerId] != msg.sender) revert Unauthorized();

        // This will revert if the caller does not own the page.
        pages.transferFrom(msg.sender, address(this), pageId);

        // Map the page to the gobbler that ate it.
        pageIdToGobblerId[pageId] = gobblerId;
    }

    /// @notice Calculate the balance of goop that is available to withdraw from a gobbler.
    function goopBalance(uint256 gobblerId) public view returns (uint256) {
        uint256 r = attributeList[gobblerId].baseRate;
        uint256 m = attributeList[gobblerId].stakingMultiple;
        uint256 s = stakingInfoMap[gobblerId].lastBalance;
        uint256 t = block.timestamp - stakingInfoMap[gobblerId].lastTimestamp;

        // TODO: idt this accounts for wads

        unchecked {
            // If a user's goop balance is greater than
            // 2**256 - 1 we've got much bigger problems.
            return ((m * t * t) / 4) + (t * (m * s + r * r).sqrt()) + s;
        }
    }

    /// @notice Add goop to gobbler for staking.
    function addGoop(uint256 gobblerId, uint256 goopAmount) public {
        if (ownerOf[gobblerId] != msg.sender) revert Unauthorized();

        // Burn goop being added to gobbler.
        goop.burnForGobblers(msg.sender, goopAmount);

        unchecked {
            // If a user has enough goop to overflow their balance we've got big problems.
            // TODO: do we maybe want to use a safecast tho? idk maybe this is not safe.
            stakingInfoMap[gobblerId].lastBalance = uint128(goopBalance(gobblerId) + goopAmount);
            stakingInfoMap[gobblerId].lastTimestamp = uint128(block.timestamp);
        }
    }

    /// @notice Remove goop from a gobbler.
    function removeGoop(uint256 gobblerId, uint256 goopAmount) public {
        if (ownerOf[gobblerId] != msg.sender) revert Unauthorized();

        // Will revert if removed amount is larger than balance.
        stakingInfoMap[gobblerId].lastBalance = uint128(goopBalance(gobblerId) - goopAmount);
        stakingInfoMap[gobblerId].lastTimestamp = uint128(block.timestamp);

        goop.mint(msg.sender, goopAmount);
    }
}
