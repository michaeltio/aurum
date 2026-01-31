// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;


import {BaseTest} from "../../helpers/Base.t.sol";

contract StakeTest is BaseTest {
    function test_RevertIf_StakeZeroAmount() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 0);
        vm.expectRevert("Cannot stake zero tokens");
        staking.stake(0);
        vm.stopPrank();
    }

    function test_RevertIf_StakeAfterRewardEnd() public {
        vm.warp(block.timestamp + 31 days);
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        vm.expectRevert("Staking period ended");
        staking.stake(100e18);
        vm.stopPrank();
    }

    function test_RevertIf_StakeWithoutApproval() public {
        vm.startPrank(user1);
        vm.expectRevert();
        staking.stake(100e18);
        vm.stopPrank();
    }

    function test_RevertIf_StakeInsufficientBalance() public {
        vm.startPrank(user1);
        uint256 balance = stakeToken.balanceOf(user1);
        stakeToken.approve(address(staking), balance + 1);
        vm.expectRevert();
        staking.stake(balance + 1);
        vm.stopPrank();
    }

    function testStakeBasicSuccess() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);

        vm.expectEmit(true, false, false, true);
        emit Staked(user1, 100e18);
        staking.stake(100e18);

        vm.stopPrank();

        assertEq(staking.totalStaked(), 100e18);
        assertEq(staking.getStakedBalance(user1), 100e18);

        (uint256 amount, uint256 rewardDebt) = staking.users(user1);
        assertEq(amount, 100e18);
        assertEq(rewardDebt, 0);
    }

    function testStakeMultipleTimesAccumulatesCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 300e18);

        staking.stake(100e18);
        assertEq(staking.totalStaked(), 100e18);

        vm.warp(block.timestamp + 1 hours);
        staking.stake(100e18);
        assertEq(staking.totalStaked(), 200e18);

        vm.warp(block.timestamp + 1 hours);
        staking.stake(100e18);
        assertEq(staking.totalStaked(), 300e18);

        vm.stopPrank();
    }

    function testStakeClaimsPendingRewardsOnSubsequentStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 200e18);

        staking.stake(100e18);
        uint256 balanceBefore = rewardToken.balanceOf(user1);

        vm.warp(block.timestamp + 1 hours);
        uint256 pendingBefore = staking.getPendingRewards(user1);

        vm.expectEmit(true, false, false, true);
        emit RewardClaimed(user1, pendingBefore);
        staking.stake(100e18);

        uint256 balanceAfter = rewardToken.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, pendingBefore);

        vm.stopPrank();
    }

    function testStakeUpdatesRewardDebtCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 200e18);

        staking.stake(100e18);
        vm.warp(block.timestamp + 1 hours);
        staking.stake(100e18);

        vm.stopPrank();

        (, uint256 rewardDebt) = staking.users(user1);
        uint256 expectedDebt = (200e18 * staking.accRewardPerShare()) / 1e12;
        assertEq(rewardDebt, expectedDebt);
    }

    function testStakeProportionalRewardDistribution() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 300e18);
        staking.stake(300e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        uint256 pending1 = staking.getPendingRewards(user1);
        uint256 pending2 = staking.getPendingRewards(user2);

        assertApproxEqRel(pending2, pending1 * 3, 0.01e18);
    }

    function testStakeLateEntrantDoesNotStealPriorRewards() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256 pending1 = staking.getPendingRewards(user1);
        uint256 pending2 = staking.getPendingRewards(user2);

        assertGt(pending1, 0);
        assertEq(pending2, 0);
    }

    function testStakeAtRewardEndTimeBoundary() public {
        uint256 endTime = block.timestamp + 30 days;
        vm.warp(endTime - 1);

        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        assertEq(staking.totalStaked(), 100e18);
    }

    function testStakeWithMaxUint256Amount() public {
        uint256 largeAmount = type(uint256).max / 2;

        vm.startPrank(owner);
        stakeToken.mint(user1, largeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        stakeToken.approve(address(staking), largeAmount);
        staking.stake(largeAmount);
        vm.stopPrank();

        assertEq(staking.totalStaked(), largeAmount);
    }

    function testStakeSameBlockNoPendingReward() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        assertEq(staking.getPendingRewards(user1), 0);
        vm.stopPrank();
    }

    function testStakeUpdatesLastRewardTime() public {
        uint256 timeBefore = staking.lastRewardTime();

        vm.warp(block.timestamp + 100);

        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256 timeAfter = staking.lastRewardTime();
        assertEq(timeAfter, block.timestamp);
        assertGt(timeAfter, timeBefore);
    }

    function testStakeMultipleUsersIndependently() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 200e18);
        staking.stake(200e18);
        vm.stopPrank();

        vm.startPrank(user3);
        stakeToken.approve(address(staking), 300e18);
        staking.stake(300e18);
        vm.stopPrank();

        assertEq(staking.totalStaked(), 600e18);
        assertEq(staking.getStakedBalance(user1), 100e18);
        assertEq(staking.getStakedBalance(user2), 200e18);
        assertEq(staking.getStakedBalance(user3), 300e18);
    }

    function testStakeUpdatesAccRewardPerShareWithExistingStakers() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256 accBefore = staking.accRewardPerShare();

        vm.warp(block.timestamp + 1 hours);

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256 accAfter = staking.accRewardPerShare();
        assertGt(accAfter, accBefore);
    }

    function testStakeAfterPartialWithdraw() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 200e18);

        staking.stake(100e18);
        vm.warp(block.timestamp + 1 hours);
        staking.withdraw(50e18);

        vm.warp(block.timestamp + 1 hours);
        staking.stake(100e18);

        vm.stopPrank();

        assertEq(staking.getStakedBalance(user1), 150e18);
    }

    function testStakeFirstStakerToEmptyPool() public {
        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        assertEq(staking.totalStaked(), 100e18);
        assertEq(staking.lastRewardTime(), block.timestamp);
    }
}
