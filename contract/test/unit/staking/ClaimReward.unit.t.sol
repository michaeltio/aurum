// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {BaseTest} from "../../helpers/Base.t.sol";

contract ClaimRewardsTest is BaseTest {
    function test_RevertIf_ClaimRewardsWithNoStake() public {
        vm.startPrank(user1);
        vm.expectRevert("No rewards");
        staking.claimRewards();
        vm.stopPrank();
    }

    function test_RevertIf_ClaimRewardsZeroPending() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        vm.expectRevert("No rewards");
        staking.claimRewards();
        vm.stopPrank();
    }

    function testClaimRewardsBasicSuccess() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pending = staking.getPendingRewards(user1);
        uint256 balanceBefore = rewardToken.balanceOf(user1);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit RewardClaimed(user1, pending);
        staking.claimRewards();

        uint256 balanceAfter = rewardToken.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, pending);
        assertGt(pending, 0);
        assertEq(staking.getPendingRewards(user1), 0);
    }

    function testClaimRewardsMultipleTimesAccumulatesCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();
        uint256 claimed1 = rewardToken.balanceOf(user1);

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();
        uint256 claimed2 = rewardToken.balanceOf(user1);

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();
        uint256 claimed3 = rewardToken.balanceOf(user1);

        assertGt(claimed1, 0);
        assertGt(claimed2, claimed1);
        assertGt(claimed3, claimed2);
    }

    function testClaimRewardsUpdatesRewardDebtCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        (, uint256 rewardDebt) = staking.users(user1);
        uint256 expectedDebt = (100e18 * staking.accRewardPerShare()) / 1e12;

        assertEq(rewardDebt, expectedDebt);
        assertGt(rewardDebt, 0);
    }

    function testClaimRewardsClearsPendingRewards() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pendingBefore = staking.getPendingRewards(user1);
        assertGt(pendingBefore, 0);

        vm.prank(user1);
        staking.claimRewards();

        uint256 pendingAfter = staking.getPendingRewards(user1);
        assertEq(pendingAfter, 0);
    }

    function testClaimRewardsDoesNotAffectStakedBalance() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 stakedBefore = staking.getStakedBalance(user1);

        vm.prank(user1);
        staking.claimRewards();

        uint256 stakedAfter = staking.getStakedBalance(user1);

        assertEq(stakedBefore, stakedAfter);
        assertEq(stakedAfter, 100e18);
    }

    function testClaimRewardsDoesNotAffectTotalStaked() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 totalBefore = staking.totalStaked();

        vm.prank(user1);
        staking.claimRewards();

        uint256 totalAfter = staking.totalStaked();

        assertEq(totalBefore, totalAfter);
        assertEq(totalAfter, 100e18);
    }

    function testClaimRewardsUpdatesPoolState() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256 lastRewardTimeBefore = staking.lastRewardTime();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        uint256 lastRewardTimeAfter = staking.lastRewardTime();

        assertGt(lastRewardTimeAfter, lastRewardTimeBefore);
        assertEq(lastRewardTimeAfter, block.timestamp);
    }

    function testClaimRewardsDoesNotAffectOtherUsers() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pending2Before = staking.getPendingRewards(user2);

        vm.prank(user1);
        staking.claimRewards();

        uint256 pending2After = staking.getPendingRewards(user2);

        assertEq(pending2Before, pending2After);
        assertGt(pending2After, 0);
    }

    function testClaimRewardsMultipleUsersIndependently() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        vm.prank(user2);
        staking.claimRewards();

        uint256 balance1 = rewardToken.balanceOf(user1);
        uint256 balance2 = rewardToken.balanceOf(user2);

        assertGt(balance1, 0);
        assertGt(balance2, 0);
        assertApproxEqRel(balance1, balance2, 0.01e18);
    }

    // function testClaimRewardsAfterRewardPeriodEnds() public {
    //     vm.startPrank(user1);
    //     stakeToken.approve(address(staking), 100e18);
    //     staking.stake(100e18);
    //     vm.stopPrank();

    //     vm.warp(block.timestamp + 31 days);

    //     uint256 pending = staking.getPendingRewards(user1);
    //     uint256 expectedMax = 30 days * 1e18;

    //     assertApproxEqRel(pending, expectedMax, 0.01e18);

    //     vm.prank(user1);
    //     staking.claimRewards();

    //     assertEq(rewardToken.balanceOf(user1), pending);
    // }

    function testClaimRewardsThenStakeAgain() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 200e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        vm.prank(user1);
        staking.stake(100e18);

        assertEq(staking.getStakedBalance(user1), 200e18);
    }

    function testClaimRewardsThenWithdraw() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        vm.prank(user1);
        staking.withdraw(50e18);

        assertEq(staking.getStakedBalance(user1), 50e18);
    }

    function testClaimRewardsWithSmallStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 1);
        staking.stake(1);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        assertGt(rewardToken.balanceOf(user1), 0);
    }

    function testClaimRewardsWithLargeStake() public {
        uint256 largeAmount = 1_000_000_000e18;

        vm.startPrank(owner);
        stakeToken.mint(user1, largeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        stakeToken.approve(address(staking), largeAmount);
        staking.stake(largeAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        vm.prank(user1);
        staking.claimRewards();

        uint256 expected = 1 hours * 1e18;
        assertApproxEqRel(rewardToken.balanceOf(user1), expected, 0.01e18);
    }

    function testClaimRewardsTransfersExactPendingAmount() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        uint256 pending = staking.getPendingRewards(user1);
        uint256 balanceBefore = rewardToken.balanceOf(user1);

        vm.prank(user1);
        staking.claimRewards();

        uint256 balanceAfter = rewardToken.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, pending);
    }

    function testClaimRewardsEmitsCorrectEvent() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pending = staking.getPendingRewards(user1);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit RewardClaimed(user1, pending);
        staking.claimRewards();
    }

    function testClaimRewardsAfterRateChange() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 balance1 = rewardToken.balanceOf(user1);

        vm.prank(owner);
        staking.setRewardRate(2e18);

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        uint256 balance2 = rewardToken.balanceOf(user1);

        uint256 claimed = balance2 - balance1;
        assertGt(claimed, 1 days * 1e18);
    }

    function testClaimRewardsConsecutivelyWithTimeGaps() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);
        vm.prank(user1);
        staking.claimRewards();
        uint256 claimed1 = rewardToken.balanceOf(user1);

        vm.warp(block.timestamp + 6 hours);
        vm.prank(user1);
        staking.claimRewards();
        uint256 claimed2 = rewardToken.balanceOf(user1);

        vm.warp(block.timestamp + 1 days);
        vm.prank(user1);
        staking.claimRewards();
        uint256 claimed3 = rewardToken.balanceOf(user1);

        assertApproxEqRel(claimed1, 1 hours * 1e18, 0.01e18);
        assertGt(claimed2, claimed1);
        assertGt(claimed3, claimed2);
    }

    function testClaimRewardsAfterPartialWithdraw() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.withdraw(50e18);

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        assertGt(rewardToken.balanceOf(user1), 0);
    }

    function testClaimRewardsAfterMultipleStakes() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 300e18);

        staking.stake(100e18);
        vm.warp(block.timestamp + 1 hours);

        staking.stake(100e18);
        vm.warp(block.timestamp + 1 hours);

        staking.stake(100e18);
        vm.warp(block.timestamp + 1 hours);

        staking.claimRewards();

        assertGt(rewardToken.balanceOf(user1), 0);
        vm.stopPrank();
    }

    function testClaimRewardsWithSafeTransferWhenInsufficientBalance() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        uint256 contractBalance = rewardToken.balanceOf(address(staking));
        uint256 pending = staking.getPendingRewards(user1);

        if (pending > contractBalance) {
            vm.prank(user1);
            staking.claimRewards();

            assertEq(rewardToken.balanceOf(user1), contractBalance);
        }
    }

    function testClaimRewardsUpdatesUserStructCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        (uint256 amountBefore, uint256 rewardDebtBefore) = staking.users(user1);

        vm.prank(user1);
        staking.claimRewards();

        (uint256 amountAfter, uint256 rewardDebtAfter) = staking.users(user1);

        assertEq(amountBefore, amountAfter);
        assertGt(rewardDebtAfter, rewardDebtBefore);
    }

    function testClaimRewardsProportionalDistribution() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 300e18);
        staking.stake(300e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        vm.prank(user2);
        staking.claimRewards();

        uint256 reward1 = rewardToken.balanceOf(user1);
        uint256 reward2 = rewardToken.balanceOf(user2);

        assertApproxEqRel(reward2, reward1 * 3, 0.01e18);
    }

    function testClaimRewardsMultipleCycles() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        for (uint256 i = 0; i < 5; i++) {
            vm.warp(block.timestamp + 1 days);
            vm.prank(user1);
            staking.claimRewards();
            assertEq(staking.getPendingRewards(user1), 0);
        }

        assertGt(rewardToken.balanceOf(user1), 0);
    }
}
