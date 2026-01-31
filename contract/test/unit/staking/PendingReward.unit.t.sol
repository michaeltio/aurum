// SPDX-License-Identifier: MIT

// pragma solidity 0.8.33;


import {BaseTest} from "../../helpers/Base.t.sol";

contract PendingRewardTest is BaseTest {
    function testGetPendingRewardsZeroForNonStaker() public view {
        assertEq(staking.getPendingRewards(user1), 0);
        assertEq(staking.getPendingRewards(address(0)), 0);
        assertEq(staking.getPendingRewards(address(999)), 0);
    }

    function testGetPendingRewardsZeroImmediatelyAfterStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        assertEq(staking.getPendingRewards(user1), 0);
    }

    function testGetPendingRewardsZeroAfterClaim() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        assertEq(staking.getPendingRewards(user1), 0);
    }

    function testGetPendingRewardsZeroAfterWithdraw() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.withdraw(50e18);

        assertEq(staking.getPendingRewards(user1), 0);
    }

    function testGetPendingRewardsZeroWithZeroRewardRate() public {
        vm.prank(owner);
        staking.setRewardRate(0);

        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        assertEq(staking.getPendingRewards(user1), 0);
    }

    function testGetPendingRewardsIncreasesWithTime() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);
        uint256 pending1 = staking.getPendingRewards(user1);

        vm.warp(block.timestamp + 1 hours);
        uint256 pending2 = staking.getPendingRewards(user1);

        vm.warp(block.timestamp + 1 hours);
        uint256 pending3 = staking.getPendingRewards(user1);

        assertGt(pending1, 0);
        assertGt(pending2, pending1);
        assertGt(pending3, pending2);
    }

    function testGetPendingRewardsLinearGrowth() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);
        uint256 pending1 = staking.getPendingRewards(user1);
        uint256 expected1 = 1 hours * 1e18;
        assertApproxEqRel(pending1, expected1, 0.01e18);

        vm.warp(block.timestamp + 1 hours);
        uint256 pending2 = staking.getPendingRewards(user1);
        uint256 expected2 = 2 hours * 1e18;
        assertApproxEqRel(pending2, expected2, 0.01e18);
    }

    function testGetPendingRewardsProportionalToStakeAmount() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 300e18);
        staking.stake(300e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pending1 = staking.getPendingRewards(user1);
        uint256 pending2 = staking.getPendingRewards(user2);

        assertGt(pending1, 0);
        assertGt(pending2, 0);
        assertApproxEqRel(pending2, pending1 * 3, 0.01e18);
    }

    function testGetPendingRewardsMultipleUsersEqualStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pending1 = staking.getPendingRewards(user1);
        uint256 pending2 = staking.getPendingRewards(user2);

        assertGt(pending1, 0);
        assertGt(pending2, 0);
        assertApproxEqRel(pending1, pending2, 0.01e18);
    }

    function testGetPendingRewardsAfterRewardPeriodEnds() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        uint256 pending = staking.getPendingRewards(user1);
        uint256 expectedMax = 30 days * 1e18;

        assertApproxEqRel(pending, expectedMax, 0.01e18);
    }

    function testGetPendingRewardsStopsAccumulatingAfterEndTime() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);
        uint256 pending1 = staking.getPendingRewards(user1);

        vm.warp(block.timestamp + 10 days);
        uint256 pending2 = staking.getPendingRewards(user1);

        assertEq(pending1, pending2);
    }

    function testGetPendingRewardsLateEntrantGetsFewerRewards() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 days);

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pending1 = staking.getPendingRewards(user1);
        uint256 pending2 = staking.getPendingRewards(user2);

        assertGt(pending1, pending2);
    }

    function testGetPendingRewardsAfterPartialWithdraw() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.withdraw(50e18);

        vm.warp(block.timestamp + 1 days);

        uint256 pending = staking.getPendingRewards(user1);
        assertGt(pending, 0);
    }

    //     function testGetPendingRewardsAfterMultipleStakes() public {
    //         vm.startPrank(user1);
    //         stakeToken.approve(address(staking), 300e18);

    //         staking.stake(100e18);
    //         vm.warp(block.timestamp + 1 hours);

    //         staking.stake(100e18);

    //         assertEq(staking.getPendingRewards(user1), 0);

    //         vm.warp(block.timestamp + 1 hours);

    //         uint256 pending = staking.getPendingRewards(user1);
    //         uint256 expected = 1 hours * 1e18 * 2;
    //         assertApproxEqRel(pending, expected, 0.01e18);

    //         vm.stopPrank();
    //     }

    function testGetPendingRewardsWithChangedRewardRate() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);
        uint256 pending1 = staking.getPendingRewards(user1);

        vm.prank(owner);
        staking.setRewardRate(2e18);

        vm.warp(block.timestamp + 1 hours);
        uint256 pending2 = staking.getPendingRewards(user1);

        uint256 increase = pending2 - pending1;
        uint256 expected = 1 hours * 2e18;
        assertApproxEqRel(increase, expected, 0.01e18);
    }

    function testGetPendingRewardsDoesNotRevert() public view {
        staking.getPendingRewards(user1);
        staking.getPendingRewards(address(0));
        staking.getPendingRewards(address(staking));
        staking.getPendingRewards(owner);
    }

    //     function testGetPendingRewardsIndependentBetweenUsers() public {
    //         vm.startPrank(user1);
    //         stakeToken.approve(address(staking), 100e18);
    //         staking.stake(100e18);
    //         vm.stopPrank();

    //         vm.warp(block.timestamp + 1 days);

    //         vm.startPrank(user2);
    //         stakeToken.approve(address(staking), 100e18);
    //         staking.stake(100e18);
    //         vm.stopPrank();

    //         vm.prank(user1);
    //         staking.claimRewards();

    //         assertEq(staking.getPendingRewards(user1), 0);
    //         assertGt(staking.getPendingRewards(user2), 0);
    //     }

    function testGetPendingRewardsWithVerySmallStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 1);
        staking.stake(1);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        uint256 pending = staking.getPendingRewards(user1);
        assertGt(pending, 0);
    }

    function testGetPendingRewardsWithVeryLargeStake() public {
        uint256 largeAmount = 1_000_000_000e18;

        vm.startPrank(owner);
        stakeToken.mint(user1, largeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        stakeToken.approve(address(staking), largeAmount);
        staking.stake(largeAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        uint256 pending = staking.getPendingRewards(user1);
        uint256 expected = 1 hours * 1e18;
        assertApproxEqRel(pending, expected, 0.01e18);
    }

    function testGetPendingRewardsAccuracyWithMultipleTimeChecks() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256[] memory times = new uint256[](5);
        times[0] = 1 hours;
        times[1] = 6 hours;
        times[2] = 1 days;
        times[3] = 7 days;
        times[4] = 15 days;

        for (uint256 i = 0; i < times.length; i++) {
            vm.warp(block.timestamp + times[i]);
            uint256 pending = staking.getPendingRewards(user1);
            assertGt(pending, 0);
        }
    }

    function testGetPendingRewardsConsistentCalculation() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pending1 = staking.getPendingRewards(user1);
        uint256 pending2 = staking.getPendingRewards(user1);
        uint256 pending3 = staking.getPendingRewards(user1);

        assertEq(pending1, pending2);
        assertEq(pending2, pending3);
    }
}
