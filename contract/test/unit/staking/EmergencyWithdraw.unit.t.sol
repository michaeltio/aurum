// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {BaseTest} from "../../helpers/Base.t.sol";

contract EmergencyWithdrawTest is BaseTest {
    function test_RevertIf_EmergencyWithdrawWithNoStake() public {
        vm.startPrank(user1);
        vm.expectRevert("Nothing to withdraw");
        staking.emergencyWithdraw();
        vm.stopPrank();
    }

    function test_RevertIf_EmergencyWithdrawAfterAlreadyWithdrawn() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        staking.emergencyWithdraw();

        vm.expectRevert("Nothing to withdraw");
        staking.emergencyWithdraw();
        vm.stopPrank();
    }

    function testEmergencyWithdrawBasicSuccess() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        uint256 balanceBefore = stakeToken.balanceOf(user1);

        vm.expectEmit(true, false, false, true);
        emit EmergencyWithdrawn(user1, 100e18);
        staking.emergencyWithdraw();

        uint256 balanceAfter = stakeToken.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 100e18);
        assertEq(staking.getStakedBalance(user1), 0);
        vm.stopPrank();
    }

    function testEmergencyWithdrawForfeitsPendingRewards() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pendingBefore = staking.getPendingRewards(user1);
        assertGt(pendingBefore, 0);

        uint256 rewardBalanceBefore = rewardToken.balanceOf(user1);

        vm.prank(user1);
        staking.emergencyWithdraw();

        uint256 rewardBalanceAfter = rewardToken.balanceOf(user1);

        assertEq(rewardBalanceAfter, rewardBalanceBefore);
        assertEq(staking.getPendingRewards(user1), 0);
    }

    function testEmergencyWithdrawResetsUserDataToZero() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.emergencyWithdraw();

        (uint256 amount, uint256 rewardDebt) = staking.users(user1);
        assertEq(amount, 0);
        assertEq(rewardDebt, 0);
    }

    function testEmergencyWithdrawDecreasesTotalStaked() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        assertEq(staking.totalStaked(), 100e18);

        vm.prank(user1);
        staking.emergencyWithdraw();

        assertEq(staking.totalStaked(), 0);
    }

    function testEmergencyWithdrawDoesNotCallUpdatePool() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 lastRewardTimeBefore = staking.lastRewardTime();
        uint256 accRewardPerShareBefore = staking.accRewardPerShare();

        vm.prank(user1);
        staking.emergencyWithdraw();

        uint256 lastRewardTimeAfter = staking.lastRewardTime();
        uint256 accRewardPerShareAfter = staking.accRewardPerShare();

        assertEq(lastRewardTimeAfter, lastRewardTimeBefore);
        assertEq(accRewardPerShareAfter, accRewardPerShareBefore);
    }

    function testEmergencyWithdrawDoesNotAffectOtherUsers() public {
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
        staking.emergencyWithdraw();

        assertEq(staking.getStakedBalance(user1), 0);
        assertEq(staking.getStakedBalance(user2), 200e18);
        assertEq(staking.getStakedBalance(user3), 300e18);
        assertEq(staking.totalStaked(), 500e18);
    }

    function testEmergencyWithdrawAllowsRestaking() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 200e18);

        staking.stake(100e18);
        staking.emergencyWithdraw();

        assertEq(staking.getStakedBalance(user1), 0);

        staking.stake(100e18);

        assertEq(staking.getStakedBalance(user1), 100e18);
        vm.stopPrank();
    }

    function testEmergencyWithdrawAfterRewardPeriodEnds() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        uint256 balanceBefore = stakeToken.balanceOf(user1);

        vm.prank(user1);
        staking.emergencyWithdraw();

        uint256 balanceAfter = stakeToken.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 100e18);
        assertEq(staking.getStakedBalance(user1), 0);
    }

    function testEmergencyWithdrawMultipleUsersIndependently() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 200e18);
        staking.stake(200e18);
        vm.stopPrank();

        vm.prank(user1);
        staking.emergencyWithdraw();

        assertEq(staking.getStakedBalance(user1), 0);
        assertEq(staking.totalStaked(), 200e18);

        vm.prank(user2);
        staking.emergencyWithdraw();

        assertEq(staking.getStakedBalance(user2), 0);
        assertEq(staking.totalStaked(), 0);
    }

    function testEmergencyWithdrawTransfersExactStakedAmount() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        uint256 userBalanceBefore = stakeToken.balanceOf(user1);
        uint256 contractBalanceBefore = stakeToken.balanceOf(address(staking));

        staking.emergencyWithdraw();

        uint256 userBalanceAfter = stakeToken.balanceOf(user1);
        uint256 contractBalanceAfter = stakeToken.balanceOf(address(staking));

        assertEq(userBalanceAfter - userBalanceBefore, 100e18);
        assertEq(contractBalanceBefore - contractBalanceAfter, 100e18);
        vm.stopPrank();
    }

    function testEmergencyWithdrawWithLargeStake() public {
        uint256 largeAmount = 1_000_000_000e18;

        vm.startPrank(owner);
        stakeToken.mint(user1, largeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        stakeToken.approve(address(staking), largeAmount);
        staking.stake(largeAmount);

        uint256 balanceBefore = stakeToken.balanceOf(user1);

        staking.emergencyWithdraw();

        uint256 balanceAfter = stakeToken.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, largeAmount);
        assertEq(staking.getStakedBalance(user1), 0);
        vm.stopPrank();
    }

    function testEmergencyWithdrawWithSmallStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 1);
        staking.stake(1);

        staking.emergencyWithdraw();

        assertEq(staking.getStakedBalance(user1), 0);
        vm.stopPrank();
    }

    function testEmergencyWithdrawEmitsCorrectEvent() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        vm.expectEmit(true, false, false, true);
        emit EmergencyWithdrawn(user1, 100e18);
        staking.emergencyWithdraw();

        vm.stopPrank();
    }

    //     function testEmergencyWithdrawLeavesOtherUserRewardsIntact() public {
    //         vm.startPrank(user1);
    //         stakeToken.approve(address(staking), 100e18);
    //         staking.stake(100e18);
    //         vm.stopPrank();

    //         vm.startPrank(user2);
    //         stakeToken.approve(address(staking), 100e18);
    //         staking.stake(100e18);
    //         vm.stopPrank();

    //         vm.warp(block.timestamp + 1 days);

    //         uint256 pending2Before = staking.getPendingRewards(user2);

    //         vm.prank(user1);
    //         staking.emergencyWithdraw();

    //         uint256 pending2After = staking.getPendingRewards(user2);

    //         assertEq(pending2Before, pending2After);
    //         assertGt(pending2After, 0);
    //     }

    function testEmergencyWithdrawSameBlockAsStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);

        staking.stake(100e18);
        staking.emergencyWithdraw();

        assertEq(staking.getStakedBalance(user1), 0);
        assertEq(staking.getPendingRewards(user1), 0);
        vm.stopPrank();
    }

    function testEmergencyWithdrawAfterMultipleStakes() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 300e18);

        staking.stake(100e18);
        vm.warp(block.timestamp + 1 hours);
        staking.stake(100e18);
        vm.warp(block.timestamp + 1 hours);
        staking.stake(100e18);

        uint256 balanceBefore = stakeToken.balanceOf(user1);

        staking.emergencyWithdraw();

        uint256 balanceAfter = stakeToken.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, 300e18);
        assertEq(staking.getStakedBalance(user1), 0);
        vm.stopPrank();
    }

    function testEmergencyWithdrawClearsAllUserState() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 5 days);

        (uint256 amountBefore, uint256 rewardDebtBefore) = staking.users(user1);
        assertGt(amountBefore, 0);

        vm.prank(user1);
        staking.emergencyWithdraw();

        (uint256 amountAfter, uint256 rewardDebtAfter) = staking.users(user1);
        assertEq(amountAfter, 0);
        assertEq(rewardDebtAfter, 0);
        assertEq(staking.getStakedBalance(user1), 0);
        assertEq(staking.getPendingRewards(user1), 0);
    }

    function testEmergencyWithdrawMultipleCycles() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 300e18);

        staking.stake(100e18);
        staking.emergencyWithdraw();
        assertEq(staking.getStakedBalance(user1), 0);

        staking.stake(100e18);
        staking.emergencyWithdraw();
        assertEq(staking.getStakedBalance(user1), 0);

        staking.stake(100e18);
        staking.emergencyWithdraw();
        assertEq(staking.getStakedBalance(user1), 0);

        vm.stopPrank();
    }

    function testEmergencyWithdrawUpdatesTotalStakedCorrectly() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 200e18);
        staking.stake(200e18);
        vm.stopPrank();

        uint256 totalBefore = staking.totalStaked();
        assertEq(totalBefore, 300e18);

        vm.prank(user1);
        staking.emergencyWithdraw();

        uint256 totalAfter = staking.totalStaked();
        assertEq(totalAfter, 200e18);
        assertEq(totalBefore - totalAfter, 100e18);
    }
}
