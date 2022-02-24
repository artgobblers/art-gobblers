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
    string private BASE_URI;

    ///@notice indicator variable for whether merkle root has been set
    bool public merkleRootIsSet = false;

    ///@notice merkle root of mint whitelist
    bytes32 public merkleRoot;

    ///@notice mapping to keep track of which addresses have claimed from whitelist
    mapping(address => bool) public claimedWhitelist;

    ///@notice timestamp for when gobblers can start being minted from goop
    uint256 public goopMintStart;

    /// ----------------------------
    /// ---- Pricing Parameters ----
    /// ----------------------------

    int256 private immutable priceScale = 0;

    int256 private immutable timeScale = 0;

    int256 private immutable timeShift = 0;

    int256 private immutable initialPrice = 0;

    int256 private immutable periodPriceDecrease = 0;

    uint256 private lastPurchaseTime;

    uint256 private numSold;

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

    ///@notice struct holding gobbler active attributes
    struct ActiveAttributes {
        uint256 issuanceRate;
        uint256 stakingMultiple;
    }

    ///@notice map token ids to active attributes
    mapping(uint256 => ActiveAttributes) public attributeMap;

    /// --------------------------
    /// -------- Addresses ------
    /// --------------------------

    Goop public goop;

    Pages public pages;

    /// --------------------------
    /// -------- Staking  --------
    /// --------------------------

    ///@notice staked balances
    mapping(uint256 => uint256) public stakedGoopBalance;

    ///@notice staked balances
    mapping(uint256 => uint256) public stakedGoopTimestamp;

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

    ///@notice randomness was fulfilled for given tokenId
    event RandomnessFulfilled(uint256 tokenId);

    ///@notice legendary gobbler was minted
    event LegendaryGobblerMint(uint256 tokenId);

    /// ----------------------
    /// -------- Errors ------
    /// ----------------------

    error Unauthorized();

    error InsufficientLinkBalance();

    error InsufficientGobblerBalance();

    error NoRemainingLegendaryGobblers();

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
        lastPurchaseTime = block.timestamp;
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
        numSold++;
    }

    ///@notice mint from goop, burning the cost
    function mintFromGoop() public {
        if (block.timestamp < goopMintStart) {
            revert Unauthorized();
        }
        goop.burn(msg.sender, gobblerPrice());
        mintGobbler(msg.sender);
        lastPurchaseTime = block.timestamp;
        numSold++;
    }

    function gobblerPrice() public view returns (uint256) {
        int256 exp = PRBMathSD59x18.fromInt(
            int256(block.timestamp - lastPurchaseTime)
        ) -
            timeShift +
            (
                (
                    (PRBMathSD59x18.fromInt(-1) + priceScale).div(
                        PRBMathSD59x18.fromInt(int256(numSold))
                    )
                ).ln().div(timeScale)
            );
        int256 scalingFactor = (PRBMathSD59x18.fromInt(1) - periodPriceDecrease)
            .pow(exp);
        int256 price = initialPrice.mul(scalingFactor);
        return uint256(price.toInt());
    }

    ///@notice mint gobbler, and request randomness for its attributes
    function mintGobbler(address mintAddress) internal {
        _mint(mintAddress, ++currentId);
        if (LINK.balanceOf(address(this)) < chainlinkFee) {
            revert InsufficientLinkBalance();
        }
        bytes32 requestId = requestRandomness(chainlinkKeyHash, chainlinkFee);
        //map request id to last minted token id
        requestIdToTokenId[requestId] = currentId;
    }

    //mint legendary gobbler
    function mintLegendaryGobbler(uint256[] calldata gobblerIds) public {
        if (remainingLegendaryGobblers == 0) {
            revert NoRemainingLegendaryGobblers();
        }
        uint256 daysSinceStart = (block.timestamp -
            currentLegendaryGobblerAuctionStart) / 1 days;
        //cost decreases by 1 gobbler per day, with min cost being 0
        uint256 cost = daysSinceStart > currentLegendaryGobblerStartPrice
            ? 0
            : currentLegendaryGobblerStartPrice - daysSinceStart;
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
        //start new auction, increasing price by 100 gobblers
        currentLegendaryGobblerAuctionStart = block.timestamp;
        currentLegendaryGobblerStartPrice += 100;
        remainingLegendaryGobblers--;
    }

    ///@notice callback from chainlink VRF. sets active attributes and seed
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 tokenId = requestIdToTokenId[requestId];
        tokenIdToRandomSeed[tokenId] = randomness;
        uint256 issuanceRate = randomness % 128;
        randomness = uint256(keccak256(abi.encodePacked(randomness)));
        uint256 stakingMultiple = randomness % 4;
        attributeMap[tokenId] = ActiveAttributes(issuanceRate, stakingMultiple);
        emit RandomnessFulfilled(tokenId);
    }

    ///@notice returns token uri if token has been minted
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (tokenId > currentId) {
            return "";
        }
        return string(abi.encodePacked(BASE_URI, tokenId.toString()));
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

    ///@notice stake goop into gobbler
    function stakeGoop(uint256 gobblerId, uint256 goopAmount) public {
        if (
            ownerOf[gobblerId] != msg.sender ||
            stakedGoopBalance[gobblerId] != 0
        ) {
            revert Unauthorized();
        }
        goop.transferFrom(msg.sender, address(this), goopAmount);
        stakedGoopBalance[gobblerId] = goopAmount;
        stakedGoopTimestamp[gobblerId] = block.timestamp;
    }

    ///@notice stake multiple gobblers in single transactinoo
    function multiStakeGoop(
        uint256[] memory gobblerIds,
        uint256[] memory goopAmounts
    ) public {
        for (uint256 i = 0; i < gobblerIds.length; i++) {
            stakeGoop(gobblerIds[i], goopAmounts[i]);
        }
    }

    ///@notice claim staking rewards
    ///todo: optimize gas usage
    function claimRewards(uint256 gobblerId) public {
        if (ownerOf[gobblerId] != msg.sender) {
            revert Unauthorized();
        }
        uint256 r = attributeMap[gobblerId].issuanceRate;
        uint256 m = attributeMap[gobblerId].stakingMultiple;
        uint256 s = stakedGoopBalance[gobblerId];
        uint256 t = block.timestamp - stakedGoopTimestamp[gobblerId];

        uint256 t1 = (m * t * t) / 4;
        uint256 t2 = t * (m * s + r * r).sqrt();
        uint256 total = t1 + t2 + s;
        uint256 reward = total - s;
        goop.mint(msg.sender, reward);
        stakedGoopTimestamp[gobblerId] = block.timestamp;
    }

    ///@notice unstake goop
    function unstakeGoop(uint256 gobblerId) public {
        if (ownerOf[gobblerId] != msg.sender) {
            revert Unauthorized();
        }
        claimRewards(gobblerId);
        goop.transfer(msg.sender, stakedGoopBalance[gobblerId]);
        stakedGoopBalance[gobblerId] = 0;
    }
}
