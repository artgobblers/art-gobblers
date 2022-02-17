// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract Benchmark {
    using FixedPointMathLib for uint256;

    mapping(uint256 => uint256) public stakedGoopBalance;
    mapping(uint256 => address) public owner;

    mapping(uint256 => uint256) public stakedGoopTimestamp;

    struct ActiveAttributes {
        uint256 issuanceRate;
        uint256 stakingMultiple;
    }
    mapping(uint256 => ActiveAttributes) public attributeMap;

    uint256 public rewardStore;

    error Unauthorized();

    function setup(
        uint256 gobblerId,
        uint256 issuance,
        uint256 multiple,
        uint256 stakeAmount,
        uint256 timestamp
    ) public {
        stakedGoopBalance[gobblerId] = stakeAmount;
        stakedGoopTimestamp[gobblerId] = timestamp;
        owner[gobblerId] = msg.sender;
        attributeMap[gobblerId] = ActiveAttributes(issuance, multiple);
    }

    function claimRewards(uint256 gobblerId) public {
        if (owner[gobblerId] != msg.sender) {
            revert Unauthorized();
        }
        uint256 r = attributeMap[gobblerId].issuanceRate;
        uint256 m = attributeMap[gobblerId].stakingMultiple;
        uint256 s = stakedGoopBalance[gobblerId];
        uint256 c = (2 * (m * s + r * r).sqrt()) / 2;
        uint256 t = block.timestamp - stakedGoopTimestamp[gobblerId];
        uint256 num = 2 *
            c *
            m *
            m *
            t +
            c *
            c *
            m *
            m +
            m *
            m *
            t *
            t -
            4 *
            r *
            r;
        uint256 total = num / (4 * m);
        uint256 reward = total - s;
        rewardStore = reward;
        stakedGoopTimestamp[gobblerId] = block.timestamp;
    }
}

contract ContractTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    Benchmark b;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        b = new Benchmark();
        uint256 timestamp = 10000000000;
        vm.warp(timestamp);
        b.setup(1, 101, 3, 10000000000, timestamp - 10000);
    }

    function testReward() public {
        b.claimRewards(1);
        assertTrue(true);
    }
}
