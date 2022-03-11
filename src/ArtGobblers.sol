// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";

import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";

import {Goop} from "./Goop.sol";
import {Pages} from "./Pages.sol";
import {VRGDA} from "./VRGDA.sol";

// TODO: UNCHECKED

/// @notice Art Gobblers scan the cosmos in search of art producing life.
contract ArtGobblers is
    ERC721("Art Gobblers", "GBLR"),
    Auth(msg.sender, Authority(address(0))),
    VRFConsumerBase,
    VRGDA
{
    using Strings for uint256;
    using FixedPointMathLib for uint256;
    using PRBMathSD59x18 for int256;

    /// ----------------------------
    /// ---- Minting Parameters ----
    /// ----------------------------

    /// @notice Id of last minted token.
    uint256 internal currentId;

    /// @notice Base URI for minted gobblers.
    string public BASE_URI;

    /// @notice URI for gobblers that have yet to be revealed.
    string public UNREVEALED_URI;

    /// @notice Merkle root of mint whitelist.
    bytes32 public merkleRoot;

    /// @notice Mapping to keep track of which addresses have claimed from whitelist.
    mapping(address => bool) public claimedWhitelist;

    /// @notice Maximum number of mintable tokens.
    uint256 public constant MAX_SUPPLY = 10000;

    /// @notice Maximum number of goop mintable tokens.
    /// @dev 10000 (max supply) - 2000 (whitelist) - 10 (legendaries)
    uint256 public constant MAX_GOOP_MINT = 7990;

    /// @notice Index of last token that has been revealed.
    uint128 public lastRevealedIndex;

    /// @notice Remaining gobblers to be assigned from seed.
    uint128 public gobblersToBeAssigned;

    /// @notice Random seed obtained from VRF.
    uint256 public randomSeed;

    /// ----------------------------
    /// ---- Pricing Parameters ----
    /// ----------------------------

    /// Pricing parameters were largely determined empirically from modeling a few different issuance curves:

    /// @notice Scale needs to be twice (MAX_GOOP_MINT + 1). Scale controls the asymptote of the logistic curve, which needs
    /// to be exactly above the max mint number. We need to multiply by 2 to adjust for the vertical translation of the curve.
    int256 private immutable logisticScale = PRBMathSD59x18.fromInt(int256((MAX_GOOP_MINT + 1) * 2));

    /// @notice Time scale of 1/60 gives us the appropriate time period for sales.
    int256 private immutable timeScale = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(60));

    /// @notice Initial price does not affect mechanism behavior at equilibrium, so can be anything.
    int256 private immutable initialPrice = PRBMathSD59x18.fromInt(69);

    /// @notice Price decrease 25% per period.
    int256 private immutable periodPriceDecrease = PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(4));

    /// @notice TimeShift is 0 to give us appropriate issuance curve
    int256 private immutable timeShift = 0;

    /// @notice Timestamp for start of mint.
    uint256 public mintStart;

    /// @notice Number of gobblers minted from goop.
    uint256 public numMintedFromGoop;

    /// --------------------
    /// -------- VRF -------
    /// --------------------

    bytes32 internal chainlinkKeyHash;

    uint256 internal chainlinkFee;

    /// @notice Map Chainlink request id to token ids.
    mapping(bytes32 => uint256) public requestIdToTokenId;

    /// @notice Map token id to random seed produced by VRF
    mapping(uint256 => uint256) public tokenIdToRandomSeed;

    /// --------------------------
    /// -------- Attributes ------
    /// --------------------------

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

    /// --------------------------
    /// -------- Addresses ------
    /// --------------------------

    Goop public goop;

    Pages public pages;

    /// --------------------------
    /// -------- Staking  --------
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

    // TODO: pack these:

    /// @notice Start price of current legendary gobbler auction.
    uint256 public currentLegendaryGobblerStartPrice;

    /// @notice Start timestamp of current legendary gobbler auction.
    uint256 public currentLegendaryGobblerAuctionStart;

    /// @notice Last 10 ids are reserved for legendary gobblers.
    uint256 private immutable LEGENDARY_GOBBLER_ID_START = MAX_SUPPLY - 10;

    /// @notice Id of last minted legendary gobbler.
    uint256 public currentLegendaryId;

    /// ----------------------------
    /// -------- Feeding Art  ------
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

    /// ----------------------
    /// -------- Errors ------
    /// ----------------------

    error Unauthorized();

    error InsufficientLinkBalance();

    error InsufficientGobblerBalance();

    error NoRemainingLegendaryGobblers();

    error NoAvailableAuctions();

    error NoRemainingGobblers();

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        string memory _baseUri
    )
        VRFConsumerBase(vrfCoordinator, linkToken)
        VRGDA(logisticScale, timeScale, timeShift, initialPrice, periodPriceDecrease)
    {
        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;
        goop = new Goop(address(this));
        pages = new Pages(address(goop), msg.sender);
        goop.setPages(address(pages));

        // Start price for legendary gobblers is 100 gobblers.
        currentLegendaryGobblerStartPrice = 100;

        // First legendary gobbler auction starts 30 days after contract deploy.
        currentLegendaryGobblerAuctionStart = block.timestamp + 30 days;

        BASE_URI = _baseUri;
        //current legendary id starts at beginning of legendary id space
        currentLegendaryId = LEGENDARY_GOBBLER_ID_START;
    }

    /// @notice Set merkle root for minting whitelist, can only be done once.
    function setMerkleRoot(bytes32 _merkleRoot) public requiresAuth {
        // Don't allow setting the merkle root twice.
        if (merkleRoot != 0) revert Unauthorized();

        merkleRoot = _merkleRoot;

        mintStart = block.timestamp;

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
        if (numMintedFromGoop >= MAX_GOOP_MINT) revert NoRemainingGobblers();

        goop.burnForGobblers(msg.sender, gobblerPrice());

        mintGobbler(msg.sender);

        numMintedFromGoop++;
    }

    /// @notice Gobbler pricing in terms of goop.
    function gobblerPrice() public view returns (uint256) {
        return getPrice(block.timestamp - mintStart, numMintedFromGoop);
    }

    function mintGobbler(address mintAddress) internal {
        uint256 newId = ++currentId;

        if (newId > MAX_SUPPLY) revert NoRemainingGobblers();

        _mint(mintAddress, newId);

        // Start generating goop from mint time.
        stakingInfoMap[currentId].lastTimestamp = uint128(block.timestamp);
    }

    /// @notice Mint a legendary gobbler by burning multiple standard gobblers.
    function mintLegendaryGobbler(uint256[] calldata gobblerIds) public {
        // When current ID surpasses max supply, we've minted all 10 legendary gobblers:
        if (currentLegendaryId >= MAX_SUPPLY) revert NoRemainingLegendaryGobblers();

        // The auction has not started yet:
        if (block.timestamp < currentLegendaryGobblerAuctionStart) revert NoAvailableAuctions();

        uint256 cost = legendaryGobblerPrice();

        if (gobblerIds.length != cost) revert InsufficientGobblerBalance();

        // Burn the gobblers provided as tribute.
        unchecked {
            for (uint256 i = 0; i < gobblerIds.length; i++) {
                if (ownerOf[gobblerIds[i]] != msg.sender) revert Unauthorized();

                _burn(gobblerIds[i]); // TODO: can inline this and skip ownership check
            }
        }

        uint256 newId = ++currentLegendaryId;

        // Mint the legendary gobbler.
        _mint(msg.sender, newId);

        // It gets a special event.
        emit LegendaryGobblerMint(newId);

        // Start a new auction, 30 days after the previous start.
        // @audit Couldn't this result in another auction being started instantly? Should we do from the perspective of now?
        currentLegendaryGobblerAuctionStart += 30 days;

        // New start price is max of (100, prev_cost*2).
        currentLegendaryGobblerStartPrice = cost < 50 ? 100 : cost << 1; // Shift left by 1 is like multiplication by 2.
    }

    /// @notice Calculate the legendary gobbler price in terms of gobblers, according to linear decay function.
    function legendaryGobblerPrice() public view returns (uint256) {
        uint256 daysSinceStart = (block.timestamp - currentLegendaryGobblerAuctionStart) / 1 days;

        // If more than 30 days have passed, legendary gobbler is free, else, decay linearly over 30 days.
        return daysSinceStart >= 30 ? 0 : (currentLegendaryGobblerStartPrice * (30 - daysSinceStart)) / 30;
    }

    /// @notice Get the random seed for revealing gobblers.
    function getRandomSeed() public returns (bytes32) {
        // A random seed can only be requested when all gobblers from previous seed have been assigned.
        // This prevents a user from requesting additional randomness in hopes of a more favorable outcome.
        if (gobblersToBeAssigned != 0) revert Unauthorized();

        if (LINK.balanceOf(address(this)) < chainlinkFee) revert InsufficientLinkBalance();

        // Fix number of gobblers to be revealed from seed.
        gobblersToBeAssigned = uint128(currentId - lastRevealedIndex);

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

        // Implements a Knuth shuffle:
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
            attributeList[currentSlot].baseRate = uint64(currentRandomSeed % 4) + 1; // @audit Wait isn't this supposed to be a constant for every gobbler?
            attributeList[currentSlot].stakingMultiple = uint64(currentRandomSeed % 128) + 1;
        }

        // @audit is gobblersToBeAssigned needed when we have lastRevealedIndex?

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
        // Between lastRevealedIndex + 1 and currentId are minted but not revealed.
        if (tokenId <= currentId) return UNREVEALED_URI;

        // Between currentId and  LEGENDARY_GOBBLER_ID_START are unminted.
        if (tokenId <= LEGENDARY_GOBBLER_ID_START) return "";

        // Between LEGENDARY_GOBBLER_ID_START and currentLegendaryId are minted legendaries.
        if (tokenId <= currentLegendaryId) return string(abi.encodePacked(BASE_URI, tokenId.toString()));

        return ""; // Unminted legendaries and invalid token ids.
    }

    /// @notice Convenience function to get staking multiple for a gobbler.
    function getStakingMultiple(uint256 tokenId) public view returns (uint256 multiple) {
        multiple = attributeList[tokenId].stakingMultiple;
    }

    /// @notice Convenience function to get the base issuance rate for a gobbler.
    function getbaseRate(uint256 tokenId) public view returns (uint256 rate) {
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

        // TODO: unchecked?
        return ((m * t * t) / 4) + (t * (m * s + r * r).sqrt()) + s;
    }

    /// @notice Add goop to gobbler for staking.
    function addGoop(uint256 gobblerId, uint256 goopAmount) public {
        if (ownerOf[gobblerId] != msg.sender) revert Unauthorized();

        // Burn goop being added to gobbler.
        goop.burnForGobblers(msg.sender, goopAmount);

        // Update last balance with newly added goop.
        stakingInfoMap[gobblerId].lastBalance = uint128(goopBalance(gobblerId) + goopAmount);
        stakingInfoMap[gobblerId].lastTimestamp = uint128(block.timestamp);
    }

    /// @notice Remove goop from a gobbler.
    function removeGoop(uint256 gobblerId, uint256 goopAmount) public {
        if (ownerOf[gobblerId] != msg.sender) revert Unauthorized();

        uint256 balance = goopBalance(gobblerId);

        // Will revert if removed amount is larger than balance.
        stakingInfoMap[gobblerId].lastBalance = uint128(balance - goopAmount);
        stakingInfoMap[gobblerId].lastTimestamp = uint128(block.timestamp);

        goop.mint(msg.sender, goopAmount);
    }
}
