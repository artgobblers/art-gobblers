// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {VRFConsumerBase} from "chainlink/v0.8/VRFConsumerBase.sol";
import {Goop} from "./Goop.sol";
import {Pages} from "./Pages.sol";

///@notice Art Gobblers scan the cosmos in search of art producing life.
contract ArtGobblers is
    ERC721("Art Gobblers", "GBLR"),
    Auth(msg.sender, Authority(address(0))),
    VRFConsumerBase
{
    using Strings for uint256;
    using FixedPointMathLib for uint256;
    using PRBMathSD59x18 for int256;

    /// ----------------------------
    /// ---- Minting Parameters ----
    /// ----------------------------

    ///@notice id of last minted token
    uint256 internal currentId;

    ///@notice base uri for minted gobblers
    string public BASE_URI;

    ///@notice uri for gobblers that have yet to be revealed
    string public UNREVEALED_URI;

    ///@notice indicator variable for whether merkle root has been set
    bool public merkleRootIsSet = false;

    ///@notice merkle root of mint whitelist
    bytes32 public merkleRoot;

    ///@notice mapping to keep track of which addresses have claimed from whitelist
    mapping(address => bool) public claimedWhitelist;

    ///@notice timestamp for when gobblers can start being minted from goop
    uint256 public goopMintStart;

    ///@notice maximum number of mintable tokens
    uint256 public constant MAX_SUPPLY = 10000;

    ///@notice index of last token that has been revealed
    uint256 public lastRevealedIndex;

    ///@notice remaining gobblers to be assigned from seed
    uint256 public gobblersToBeAssigned;

    ///@notice random seed obtained from VRF
    uint256 public randomSeed;

    /// ----------------------------
    /// ---- Pricing Parameters ----
    /// ----------------------------

    int256 private immutable priceScale = PRBMathSD59x18.fromInt(15982);

    int256 private immutable timeScale =
        PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(60));

    int256 private immutable initialPrice = PRBMathSD59x18.fromInt(69);

    int256 private immutable periodPriceDecrease =
        PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(4));

    int256 private immutable dayScaling = PRBMathSD59x18.fromInt(24 * 60 * 60);

    uint256 private lastPurchaseTime;

    /// --------------------
    /// -------- VRF -------
    /// --------------------

    bytes32 internal chainlinkKeyHash;

    uint256 internal chainlinkFee;

    ///@notice map chainlink request id to token ids
    mapping(bytes32 => uint256) public requestIdToTokenId;

    ///@notice map token id to random seed produced by vrf
    mapping(uint256 => uint256) public tokenIdToRandomSeed;

    /// --------------------------
    /// -------- Attributes ------
    /// --------------------------

    ///@notice struct holding gobbler attributes
    struct GobblerAttributes {
        ///@notice index of token after shuffl e
        uint128 idx;
        ///@notice base issuance rate for goop
        uint64 baseRate;
        ///@notice multiple on goop issuance
        uint64 stakingMultiple;
    }

    GobblerAttributes[MAX_SUPPLY + 1] public attributeList;

    /// --------------------------
    /// -------- Addresses ------
    /// --------------------------

    Goop public goop;

    Pages public pages;

    /// --------------------------
    /// -------- Staking  --------
    /// --------------------------

    ///@notice struct holding info required for goop staking reward calculation
    struct StakingInfo {
        ///@notice balance at time of last deposit or withdrawal
        uint256 lastBalance;
        ///@notice timestamp of last deposit or widthdrawal
        uint256 lastTimestamp;
    }

    ///@notice mapping from tokenId to staking info
    mapping(uint256 => StakingInfo) public stakingInfoMap;

    /// -------------------------------
    /// ----- Legendary Gobblers  -----
    /// -------------------------------

    ///@notice start price of current legendary gobbler auction
    uint256 currentLegendaryGobblerStartPrice;

    ///@notice start timestamp of current legendary gobbler auction
    uint256 currentLegendaryGobblerAuctionStart;

    ///@notice number of legendary gobblers that remain to be minted
    uint256 remainingLegendaryGobblers = 10;

    /// ----------------------------
    /// -------- Feeding Art  ------
    /// ----------------------------

    ///@notice mapping from page ids to gobbler ids that were fed
    mapping(uint256 => uint256) public pageIdToGobblerId;

    /// ----------------------
    /// -------- Events ------
    /// ----------------------

    ///@notice merkle root was set
    event MerkleRootSet(bytes32 merkleRoot);

    ///@notice legendary gobbler was minted
    event LegendaryGobblerMint(uint256 tokenId);

    /// ----------------------
    /// -------- Errors ------
    /// ----------------------

    error Unauthorized();

    error InsufficientLinkBalance();

    error InsufficientGobblerBalance();

    error NoRemainingLegendaryGobblers();

    error NoAvailableAuctions();

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 _chainlinkKeyHash,
        uint256 _chainlinkFee,
        string memory _baseUri
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;
        goop = new Goop(address(this));
        pages = new Pages(address(goop), msg.sender);
        goop.setPages(address(pages));
        //start price for legendary gobblers is 100 gobblers
        currentLegendaryGobblerStartPrice = 100;
        //first legendary gobbler auction starts 30 days after contract deploy
        currentLegendaryGobblerAuctionStart = block.timestamp + 30 days;
        goopMintStart = block.timestamp + 2 days;
        lastPurchaseTime = goopMintStart;
        BASE_URI = _baseUri;
    }

    ///@notice set merkle root for minting whitelist, can only be done once
    function setMerkleRoot(bytes32 _merkleRoot) public requiresAuth {
        if (merkleRootIsSet) {
            revert Unauthorized();
        }
        merkleRoot = _merkleRoot;
        merkleRootIsSet = true;
        emit MerkleRootSet(_merkleRoot);
    }

    ///@notice mint from whitelist, providing merkle proof
    function mintFromWhitelist(bytes32[] calldata _merkleProof) public {
        if (!merkleRootIsSet || claimedWhitelist[msg.sender]) {
            revert Unauthorized();
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            revert Unauthorized();
        }
        claimedWhitelist[msg.sender] = true;
        mintGobbler(msg.sender);
        //whitelisted users also get a free page
        pages.mintByAuth(msg.sender);
    }

    ///@notice mint from goop, burning the cost
    function mintFromGoop() public {
        if (block.timestamp < goopMintStart) {
            revert Unauthorized();
        }
        goop.burn(msg.sender, gobblerPrice());
        mintGobbler(msg.sender);
        lastPurchaseTime = block.timestamp;
    }

    function gobblerPrice() public view returns (uint256) {
        int256 logistic_value = PRBMathSD59x18.fromInt(int256(currentId)) +
            priceScale.div(PRBMathSD59x18.fromInt(1) + timeScale.exp());

        int256 exp = PRBMathSD59x18
            .fromInt(int256(block.timestamp - lastPurchaseTime))
            .div(dayScaling) +
            (
                ((priceScale).div(logistic_value) - PRBMathSD59x18.fromInt(1))
                    .ln()
                    .div(timeScale)
            );
        int256 scalingFactor = (PRBMathSD59x18.fromInt(1) - periodPriceDecrease)
            .pow(exp);
        int256 price = initialPrice.mul(scalingFactor);
        return uint256(price.toInt());
    }

    function mintGobbler(address mintAddress) internal {
        _mint(mintAddress, ++currentId);
        //start generating goop from mint time
        stakingInfoMap[currentId].lastTimestamp = block.timestamp;
    }

    //mint legendary gobbler
    function mintLegendaryGobbler(uint256[] calldata gobblerIds) public {
        if (remainingLegendaryGobblers == 0) {
            revert NoRemainingLegendaryGobblers();
        }
        //auction has not started yet
        if (block.timestamp < currentLegendaryGobblerAuctionStart) {
            revert NoAvailableAuctions();
        }
        uint256 cost = legendaryGobblerPrice();
        if (gobblerIds.length != cost) {
            revert InsufficientGobblerBalance();
        }
        //burn payment
        for (uint256 i = 0; i < gobblerIds.length; i++) {
            if (ownerOf[gobblerIds[i]] != msg.sender) {
                revert Unauthorized();
            }
            _burn(gobblerIds[i]);
        }
        //mint new gobblers
        _mint(msg.sender, ++currentId);
        //emit event with id of last mint
        emit LegendaryGobblerMint(currentId);
        //start new auction, with double the purchase price, 30 days after start
        currentLegendaryGobblerAuctionStart += 30 days;
        //new start price is max of (100, prev_cost*2)
        currentLegendaryGobblerStartPrice = cost < 50 ? 100 : cost << 1;
        remainingLegendaryGobblers--;
    }

    ///@notice calculate legendary gobbler price, according to linear decay function
    function legendaryGobblerPrice() public view returns (uint256) {
        uint256 daysSinceStart = (block.timestamp -
            currentLegendaryGobblerAuctionStart) / 1 days;

        //if more than 30 days have passed, legendary gobbler is free, else, decay linearly over 30 days
        uint256 cost = daysSinceStart >= 30
            ? 0
            : (currentLegendaryGobblerStartPrice * (30 - daysSinceStart)) / 30;
        return cost;
    }

    ///@notice get random seed for revealing gobblers
    function getRandomSeed() public returns (bytes32) {
        //a random seed can only be requested when all gobblers from previous seed
        //have been assigned. This prevents a user from requesting additional randomness
        //in hopes of a more favorable outcome
        if (gobblersToBeAssigned != 0) {
            revert Unauthorized();
        }
        if (LINK.balanceOf(address(this)) < chainlinkFee) {
            revert InsufficientLinkBalance();
        }
        //fix number of gobblers to be revealed from seed
        gobblersToBeAssigned = currentId - lastRevealedIndex;
        return requestRandomness(chainlinkKeyHash, chainlinkFee);
    }

    ///@notice callback from chainlink VRF. sets active attributes and seed
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomSeed = randomness;
    }

    ///@notice knuth shuffle to progressively reveal gobblers using entropy from random seed
    function revealGobblers(uint256 numGobblers) public {
        //cant reveal more gobblers than were available when seed was generated
        if (numGobblers > gobblersToBeAssigned) {
            revert Unauthorized();
        }
        //knuth shuffle
        for (uint256 i = 0; i < numGobblers; i++) {
            //number of slots that have not been assigned
            uint256 remainingSlots = MAX_SUPPLY - lastRevealedIndex;
            //randomly pick distance for swap
            uint256 distance = randomSeed % remainingSlots;
            //select swap slot, adding distance to next reveal slot
            uint256 swapSlot = lastRevealedIndex + 1 + distance;
            //if index in swap slot is 0, that means slot has never been touched.
            //thus, it has the default value, which is the slot index
            uint128 swapIndex = attributeList[swapSlot].idx == 0
                ? uint128(swapSlot)
                : attributeList[swapSlot].idx;
            //current slot is consecutive to last reveal
            uint256 currentSlot = lastRevealedIndex + 1;
            //again, we derive index based on value
            uint128 currentIndex = attributeList[currentSlot].idx == 0
                ? uint128(currentSlot)
                : attributeList[currentSlot].idx;
            //swap indices
            attributeList[currentSlot].idx = swapIndex;
            attributeList[swapSlot].idx = currentIndex;
            //select random attributes for current slot
            randomSeed = uint256(keccak256(abi.encodePacked(randomSeed)));
            attributeList[currentSlot].baseRate = uint64(randomSeed % 4) + 1;
            randomSeed = uint256(keccak256(abi.encodePacked(randomSeed)));
            attributeList[currentSlot].stakingMultiple =
                uint64(randomSeed % 128) +
                1;
            //update seed for next iteration
            randomSeed = uint256(keccak256(abi.encodePacked(randomSeed)));
            //increment last reveal index
            lastRevealedIndex++;
        }
        //update gobblers remainig to be assigned
        gobblersToBeAssigned -= numGobblers;
    }

    ///@notice returns token uri if token has been minted
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        //not minted
        if (tokenId > currentId) {
            return "";
        }
        //not revealed
        if (tokenId > lastRevealedIndex) {
            return UNREVEALED_URI;
        }
        //revealed
        return
            string(
                abi.encodePacked(
                    BASE_URI,
                    uint256(attributeList[tokenId].idx).toString()
                )
            );
    }

    ///@notice convenience function to get staking multiple
    function getStakingMultiple(uint256 tokenId)
        public
        view
        returns (uint256 multiple)
    {
        multiple = attributeList[tokenId].stakingMultiple;
    }

    ///@notice convenience function to get base issuance rate
    function getbaseRate(uint256 tokenId) public view returns (uint256 rate) {
        rate = attributeList[tokenId].baseRate;
    }

    ///@notice feed gobbler a page
    function feedArt(uint256 gobblerId, uint256 pageId) public {
        if (
            pages.ownerOf(pageId) != msg.sender ||
            !pages.isDrawn(pageId) ||
            ownerOf[gobblerId] != msg.sender
        ) {
            revert Unauthorized();
        }
        pages.transferFrom(msg.sender, address(this), pageId);
        pageIdToGobblerId[pageId] = gobblerId;
    }

    ///@notice calculate the balance of goop that is available to withdraw
    function goopBalance(uint256 gobblerId) public view returns (uint256) {
        uint256 r = attributeList[gobblerId].baseRate;
        uint256 m = attributeList[gobblerId].stakingMultiple;
        uint256 s = stakingInfoMap[gobblerId].lastBalance;
        uint256 t = block.timestamp - stakingInfoMap[gobblerId].lastTimestamp;

        uint256 t1 = (m * t * t) / 4;
        uint256 t2 = t * (m * s + r * r).sqrt();
        return t1 + t2 + s;
    }

    ///@notice add goop to gobbler for staking
    function addGoop(uint256 gobblerId, uint256 goopAmount) public {
        if (ownerOf[gobblerId] != msg.sender) {
            revert Unauthorized();
        }
        //burn goop being added to gobbler
        goop.burn(msg.sender, goopAmount);
        //calculate current balance and newly added goop
        stakingInfoMap[gobblerId].lastBalance =
            goopBalance(gobblerId) +
            goopAmount;
        stakingInfoMap[gobblerId].lastTimestamp = block.timestamp;
    }

    ///@notice remove goop from gobbler
    function removeGoop(uint256 gobblerId, uint256 goopAmount) public {
        if (ownerOf[gobblerId] != msg.sender) {
            revert Unauthorized();
        }
        uint256 balance = goopBalance(gobblerId);
        //will revert if removed amount is larger than balance
        stakingInfoMap[gobblerId].lastBalance = balance - goopAmount;
        stakingInfoMap[gobblerId].lastTimestamp = block.timestamp;
        goop.mint(msg.sender, goopAmount);
    }
}
