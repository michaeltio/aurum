// SPDX-License-Identifier: MIT

// pragma solidity 0.8.33;


import {BaseTest} from "../../helpers/Base.t.sol";
import {Constants} from "../../helpers/Constants.t.sol";

contract FundRewardTest is BaseTest {
    function test_RevertIf_FundRewardsZeroAmount() public {
        vm.startPrank(owner);
        vm.expectRevert("Zero amount");
        staking.fundRewards(0);
        vm.stopPrank();
    }

    function test_RevertIf_FundRewardsNonOwner() public {
        uint256 fundAmount = 10000e18;

        vm.startPrank(user1);
        rewardToken.approve(address(staking), fundAmount);
        vm.expectRevert();
        staking.fundRewards(fundAmount);
        vm.stopPrank();
    }

    function test_RevertIf_FundRewardsWithoutApproval() public {
        uint256 fundAmount = 10000e18;

        vm.startPrank(owner);
        rewardToken.mint(owner, fundAmount);
        vm.expectRevert();
        staking.fundRewards(fundAmount);
        vm.stopPrank();
    }

    function test_RevertIf_FundRewardsInsufficientBalance() public {
        uint256 fundAmount = 10000e18;
        uint256 balance = rewardToken.balanceOf(owner);

        vm.startPrank(owner);
        rewardToken.approve(address(staking), balance + fundAmount);
        vm.expectRevert();
        staking.fundRewards(balance + fundAmount);
        vm.stopPrank();
    }

    function testFundRewardsBasicSuccess() public {
        uint256 fundAmount = 10000e18;

        vm.startPrank(owner);
        rewardToken.mint(owner, fundAmount);
        rewardToken.approve(address(staking), fundAmount);

        uint256 contractBalanceBefore = rewardToken.balanceOf(address(staking));
        uint256 ownerBalanceBefore = rewardToken.balanceOf(owner);

        vm.expectEmit(true, false, false, true);
        emit RewardsFunded(fundAmount);
        staking.fundRewards(fundAmount);

        uint256 contractBalanceAfter = rewardToken.balanceOf(address(staking));
        uint256 ownerBalanceAfter = rewardToken.balanceOf(owner);

        assertEq(contractBalanceAfter - contractBalanceBefore, fundAmount);
        assertEq(ownerBalanceBefore - ownerBalanceAfter, fundAmount);
        vm.stopPrank();
    }

    function testFundRewardsMultipleTimes() public {
        vm.startPrank(owner);
        rewardToken.mint(owner, 30000e18);
        rewardToken.approve(address(staking), 30000e18);

        uint256 balanceBefore = rewardToken.balanceOf(address(staking));

        staking.fundRewards(10000e18);
        staking.fundRewards(10000e18);
        staking.fundRewards(10000e18);

        uint256 balanceAfter = rewardToken.balanceOf(address(staking));

        assertEq(balanceAfter - balanceBefore, 30000e18);
        vm.stopPrank();
    }

    function testFundRewardsLargeAmount() public {
        uint256 largeAmount = 1_000_000_000e18;

        vm.startPrank(owner);
        rewardToken.mint(owner, largeAmount);
        rewardToken.approve(address(staking), largeAmount);

        uint256 balanceBefore = rewardToken.balanceOf(address(staking));

        staking.fundRewards(largeAmount);

        uint256 balanceAfter = rewardToken.balanceOf(address(staking));

        assertEq(balanceAfter - balanceBefore, largeAmount);
        assertEq(balanceAfter, Constants.REWARD_POOL + largeAmount);
        vm.stopPrank();
    }

    function testFundRewardsSmallAmount() public {
        uint256 smallAmount = 1;

        vm.startPrank(owner);
        rewardToken.mint(owner, smallAmount);
        rewardToken.approve(address(staking), smallAmount);

        uint256 balanceBefore = rewardToken.balanceOf(address(staking));

        staking.fundRewards(smallAmount);

        uint256 balanceAfter = rewardToken.balanceOf(address(staking));

        assertEq(balanceAfter - balanceBefore, smallAmount);
        vm.stopPrank();
    }

    function testFundRewardsEmitsCorrectEvent() public {
        uint256 fundAmount = 10000e18;

        vm.startPrank(owner);
        rewardToken.mint(owner, fundAmount);
        rewardToken.approve(address(staking), fundAmount);

        vm.expectEmit(true, false, false, true);
        emit RewardsFunded(fundAmount);
        staking.fundRewards(fundAmount);

        vm.stopPrank();
    }

    function testFundRewardsDoesNotAffectStaking() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256 stakedBefore = staking.getStakedBalance(user1);
        uint256 totalStakedBefore = staking.totalStaked();

        vm.startPrank(owner);
        rewardToken.mint(owner, 10000e18);
        rewardToken.approve(address(staking), 10000e18);
        staking.fundRewards(10000e18);
        vm.stopPrank();

        uint256 stakedAfter = staking.getStakedBalance(user1);
        uint256 totalStakedAfter = staking.totalStaked();

        assertEq(stakedBefore, stakedAfter);
        assertEq(totalStakedBefore, totalStakedAfter);
    }

    function testFundRewardsDoesNotAffectPendingRewards() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        uint256 pendingBefore = staking.getPendingRewards(user1);

        vm.startPrank(owner);
        rewardToken.mint(owner, 10000e18);
        rewardToken.approve(address(staking), 10000e18);
        staking.fundRewards(10000e18);
        vm.stopPrank();

        uint256 pendingAfter = staking.getPendingRewards(user1);

        assertEq(pendingBefore, pendingAfter);
    }

    function testFundRewardsDoesNotUpdatePoolState() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        uint256 lastRewardTimeBefore = staking.lastRewardTime();
        uint256 accRewardPerShareBefore = staking.accRewardPerShare();

        vm.startPrank(owner);
        rewardToken.mint(owner, 10000e18);
        rewardToken.approve(address(staking), 10000e18);
        staking.fundRewards(10000e18);
        vm.stopPrank();

        uint256 lastRewardTimeAfter = staking.lastRewardTime();
        uint256 accRewardPerShareAfter = staking.accRewardPerShare();

        assertEq(lastRewardTimeBefore, lastRewardTimeAfter);
        assertEq(accRewardPerShareBefore, accRewardPerShareAfter);
    }

    function testFundRewardsCanBeCalledAnytime() public {
        vm.startPrank(owner);
        rewardToken.mint(owner, 30000e18);
        rewardToken.approve(address(staking), 30000e18);

        staking.fundRewards(10000e18);

        vm.warp(block.timestamp + 10 days);
        staking.fundRewards(10000e18);

        vm.warp(block.timestamp + 25 days);
        staking.fundRewards(10000e18);

        assertEq(
            rewardToken.balanceOf(address(staking)),
            Constants.REWARD_POOL + 30000e18
        );
        vm.stopPrank();
    }

    function testFundRewardsAfterRewardPeriodEnds() public {
        vm.warp(block.timestamp + 31 days);

        vm.startPrank(owner);
        rewardToken.mint(owner, 10000e18);
        rewardToken.approve(address(staking), 10000e18);

        staking.fundRewards(10000e18);

        assertEq(
            rewardToken.balanceOf(address(staking)),
            Constants.REWARD_POOL + 10000e18
        );
        vm.stopPrank();
    }

    function testFundRewardsIncrementsContractBalance() public {
        uint256 balanceInitial = rewardToken.balanceOf(address(staking));

        vm.startPrank(owner);
        rewardToken.mint(owner, 50000e18);
        rewardToken.approve(address(staking), 50000e18);

        staking.fundRewards(10000e18);
        uint256 balance1 = rewardToken.balanceOf(address(staking));
        assertEq(balance1, balanceInitial + 10000e18);

        staking.fundRewards(20000e18);
        uint256 balance2 = rewardToken.balanceOf(address(staking));
        assertEq(balance2, balanceInitial + 30000e18);

        staking.fundRewards(20000e18);
        uint256 balance3 = rewardToken.balanceOf(address(staking));
        assertEq(balance3, balanceInitial + 50000e18);

        vm.stopPrank();
    }

    function testFundRewardsWithActiveStakers() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 200e18);
        staking.stake(200e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        uint256 pending1Before = staking.getPendingRewards(user1);
        uint256 pending2Before = staking.getPendingRewards(user2);

        vm.startPrank(owner);
        rewardToken.mint(owner, 100000e18);
        rewardToken.approve(address(staking), 100000e18);
        staking.fundRewards(100000e18);
        vm.stopPrank();

        uint256 pending1After = staking.getPendingRewards(user1);
        uint256 pending2After = staking.getPendingRewards(user2);

        assertEq(pending1Before, pending1After);
        assertEq(pending2Before, pending2After);
    }

    function testFundRewardsAllowsContinuousDistribution() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        uint256 pending1 = staking.getPendingRewards(user1);

        vm.startPrank(owner);
        rewardToken.mint(owner, 500000e18);
        rewardToken.approve(address(staking), 500000e18);
        staking.fundRewards(500000e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        uint256 pending2 = staking.getPendingRewards(user1);

        assertGt(pending2, pending1);
    }

    function testFundRewardsMultipleOwnerCalls() public {
        vm.startPrank(owner);

        rewardToken.mint(owner, 100000e18);
        rewardToken.approve(address(staking), 100000e18);

        for (uint256 i = 0; i < 10; i++) {
            staking.fundRewards(10000e18);
        }

        assertEq(
            rewardToken.balanceOf(address(staking)),
            Constants.REWARD_POOL + 100000e18
        );

        vm.stopPrank();
    }

    function testFundRewardsTransfersExactAmount() public {
        uint256 fundAmount = 12345e18;

        vm.startPrank(owner);
        rewardToken.mint(owner, fundAmount);

        uint256 ownerBalanceBefore = rewardToken.balanceOf(owner);
        uint256 contractBalanceBefore = rewardToken.balanceOf(address(staking));

        rewardToken.approve(address(staking), fundAmount);
        staking.fundRewards(fundAmount);

        uint256 ownerBalanceAfter = rewardToken.balanceOf(owner);
        uint256 contractBalanceAfter = rewardToken.balanceOf(address(staking));

        assertEq(ownerBalanceBefore - ownerBalanceAfter, fundAmount);
        assertEq(contractBalanceAfter - contractBalanceBefore, fundAmount);

        vm.stopPrank();
    }
}
