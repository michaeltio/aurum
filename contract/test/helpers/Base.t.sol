//SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Test, console2} from "forge-std/Test.sol";
import {Staking} from "../../contracts/Staking.sol";
import {MockERC20} from "./MockERC20.sol";
import {Constants} from "./Constants.t.sol";

abstract contract BaseTest is Test {
    Staking public staking;
    MockERC20 public stakeToken;
    MockERC20 public rewardToken;

    address public owner;
    address public user1;
    address public user2;
    address public user3;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event RewardsFunded(uint256 amount);
    event RewardEndTimeUpdated(uint256 newEndTime);

    function setUp() public virtual {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        vm.startPrank(owner);

        stakeToken = new MockERC20("StakeToken", "STK");
        rewardToken = new MockERC20("RewardToken", "RWT");
        staking = new Staking(address(stakeToken), address(rewardToken));

        rewardToken.mint(owner, Constants.REWARD_POOL);
        stakeToken.mint(user1, Constants.INITIAL_BALANCE);
        stakeToken.mint(user2, Constants.INITIAL_BALANCE);
        stakeToken.mint(user3, Constants.INITIAL_BALANCE);

        rewardToken.approve(address(staking), Constants.REWARD_POOL);
        staking.fundRewards(Constants.REWARD_POOL);

        staking.setRewardEndTime(block.timestamp + Constants.REWARD_DURATION);
        staking.setRewardRate(Constants.REWARD_RATE);

        vm.stopPrank();
    }
}
