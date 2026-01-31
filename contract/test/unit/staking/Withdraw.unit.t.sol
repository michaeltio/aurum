// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {BaseTest} from "../../helpers/Base.t.sol";

contract WithdrawTest is BaseTest {
    function test_RevertIf_WithdrawZeroAmount() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        vm.expectRevert("Cannot Withdraw 0 Amount");
        staking.withdraw(0);
        vm.stopPrank();
    }

    function test_RevertIf_WithdrawMoreThanStaked() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        vm.expectRevert("Not enough staked");
        staking.withdraw(150e18);
        vm.stopPrank();
    }

    function test_RevertIf_WithdrawWithNoStake() public {
        vm.startPrank(user1);
        vm.expectRevert("Not enough staked");
        staking.withdraw(100e18);
        vm.stopPrank();
    }

    function test_RevertIf_WithdrawExceedsBalance() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        vm.expectRevert("Not enough staked");
        staking.withdraw(type(uint256).max);
        vm.stopPrank();
    }

    function testWithdrawFullAmountSuccess() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        uint256 balanceBefore = stakeToken.balanceOf(user1);

        vm.expectEmit(true, false, false, true);
        emit Withdrawn(user1, 100e18);
        staking.withdraw(100e18);

        uint256 balanceAfter = stakeToken.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 100e18);
        assertEq(staking.getStakedBalance(user1), 0);
        assertEq(staking.totalStaked(), 0);
        vm.stopPrank();
    }

    function testWithdrawPartialAmount() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        staking.withdraw(30e18);

        assertEq(staking.getStakedBalance(user1), 70e18);
        assertEq(staking.totalStaked(), 70e18);
        vm.stopPrank();
    }

    function testWithdrawMultipleTimesSequentially() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 300e18);
        staking.stake(300e18);

        staking.withdraw(100e18);
        assertEq(staking.getStakedBalance(user1), 200e18);
        assertEq(staking.totalStaked(), 200e18);

        staking.withdraw(100e18);
        assertEq(staking.getStakedBalance(user1), 100e18);
        assertEq(staking.totalStaked(), 100e18);

        staking.withdraw(100e18);
        assertEq(staking.getStakedBalance(user1), 0);
        assertEq(staking.totalStaked(), 0);
        vm.stopPrank();
    }

    function testWithdrawAutomaticallyClaimsPendingRewards() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        uint256 pendingBefore = staking.getPendingRewards(user1);
        uint256 rewardBalanceBefore = rewardToken.balanceOf(user1);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit RewardClaimed(user1, pendingBefore);
        staking.withdraw(50e18);

        uint256 rewardBalanceAfter = rewardToken.balanceOf(user1);

        assertEq(rewardBalanceAfter - rewardBalanceBefore, pendingBefore);
        assertGt(pendingBefore, 0);
    }

    function testWithdrawUpdatesRewardDebtCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        vm.prank(user1);
        staking.withdraw(50e18);

        (, uint256 rewardDebt) = staking.users(user1);
        uint256 expectedDebt = (50e18 * staking.accRewardPerShare()) / 1e12;
        assertEq(rewardDebt, expectedDebt);
    }

    function testWithdrawClearsPendingRewards() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pendingBefore = staking.getPendingRewards(user1);
        assertGt(pendingBefore, 0);

        vm.prank(user1);
        staking.withdraw(50e18);

        assertEq(staking.getPendingRewards(user1), 0);
    }

    function testWithdrawAfterRewardPeriodEnds() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        uint256 balanceBefore = stakeToken.balanceOf(user1);

        vm.prank(user1);
        staking.withdraw(100e18);

        uint256 balanceAfter = stakeToken.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 100e18);
        assertEq(staking.getStakedBalance(user1), 0);
    }

    function testWithdrawDoesNotAffectOtherUsers() public {
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

        vm.prank(user1);
        staking.withdraw(50e18);

        assertEq(staking.getStakedBalance(user2), 200e18);
        assertEq(staking.getStakedBalance(user3), 300e18);
        assertEq(staking.totalStaked(), 550e18);
    }

    function testWithdrawMultipleUsersIndependently() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 200e18);
        staking.stake(200e18);
        vm.stopPrank();

        vm.prank(user1);
        staking.withdraw(50e18);

        vm.prank(user2);
        staking.withdraw(100e18);

        assertEq(staking.getStakedBalance(user1), 50e18);
        assertEq(staking.getStakedBalance(user2), 100e18);
        assertEq(staking.totalStaked(), 150e18);
    }

    function testWithdrawThenRestake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 300e18);

        staking.stake(100e18);
        staking.withdraw(50e18);
        staking.stake(100e18);

        assertEq(staking.getStakedBalance(user1), 150e18);
        vm.stopPrank();
    }

    function testWithdrawSameBlockAsStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 200e18);

        staking.stake(100e18);
        staking.withdraw(50e18);

        assertEq(staking.getStakedBalance(user1), 50e18);
        assertEq(staking.getPendingRewards(user1), 0);
        vm.stopPrank();
    }

    function testWithdrawSmallAmount() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        staking.withdraw(1);

        assertEq(staking.getStakedBalance(user1), 100e18 - 1);
        vm.stopPrank();
    }

    function testWithdrawLargeAmount() public {
        uint256 largeAmount = 1_000_000_000e18;

        vm.startPrank(owner);
        stakeToken.mint(user1, largeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        stakeToken.approve(address(staking), largeAmount);
        staking.stake(largeAmount);

        staking.withdraw(largeAmount / 2);

        assertEq(staking.getStakedBalance(user1), largeAmount / 2);
        vm.stopPrank();
    }

    function testWithdrawUpdatesUserStructCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        (uint256 amountBefore, ) = staking.users(user1);

        staking.withdraw(50e18);

        (uint256 amountAfter, ) = staking.users(user1);

        assertEq(amountBefore - amountAfter, 50e18);
        assertEq(amountAfter, 50e18);
        vm.stopPrank();
    }

    function testWithdrawUpdatesTotalStakedCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 200e18);
        staking.stake(200e18);
        vm.stopPrank();

        uint256 totalBefore = staking.totalStaked();

        vm.prank(user1);
        staking.withdraw(50e18);

        uint256 totalAfter = staking.totalStaked();

        assertEq(totalBefore - totalAfter, 50e18);
        assertEq(totalAfter, 250e18);
    }

    function testWithdrawEmitsCorrectEvent() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        vm.expectEmit(true, false, false, true);
        emit Withdrawn(user1, 50e18);
        staking.withdraw(50e18);

        vm.stopPrank();
    }

    function testWithdrawTransfersCorrectTokenAmount() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        uint256 contractBalanceBefore = stakeToken.balanceOf(address(staking));
        uint256 userBalanceBefore = stakeToken.balanceOf(user1);

        staking.withdraw(100e18);

        uint256 contractBalanceAfter = stakeToken.balanceOf(address(staking));
        uint256 userBalanceAfter = stakeToken.balanceOf(user1);

        assertEq(contractBalanceBefore - contractBalanceAfter, 100e18);
        assertEq(userBalanceAfter - userBalanceBefore, 100e18);
        vm.stopPrank();
    }

    function testWithdrawAfterMultipleStakesAndWithdraws() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 500e18);

        staking.stake(100e18);
        staking.withdraw(50e18);
        staking.stake(100e18);
        staking.withdraw(30e18);
        staking.stake(50e18);

        assertEq(staking.getStakedBalance(user1), 170e18);

        staking.withdraw(170e18);
        assertEq(staking.getStakedBalance(user1), 0);

        vm.stopPrank();
    }

    function testWithdrawUpdatesPoolState() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256 lastRewardTimeBefore = staking.lastRewardTime();

        vm.warp(block.timestamp + 1 hours);

        vm.prank(user1);
        staking.withdraw(50e18);

        uint256 lastRewardTimeAfter = staking.lastRewardTime();

        assertGt(lastRewardTimeAfter, lastRewardTimeBefore);
        assertEq(lastRewardTimeAfter, block.timestamp);
    }

    function testWithdrawWithAccumulatedRewardsOverTime() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        uint256 pending1 = staking.getPendingRewards(user1);

        vm.warp(block.timestamp + 1 days);
        uint256 pending2 = staking.getPendingRewards(user1);

        assertGt(pending2, pending1);

        vm.prank(user1);
        staking.withdraw(50e18);

        uint256 rewardBalance = rewardToken.balanceOf(user1);
        assertEq(rewardBalance, pending2);
    }
}
