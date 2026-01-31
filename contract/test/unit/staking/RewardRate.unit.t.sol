//SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {BaseTest} from "../../helpers/Base.t.sol";

contract RewardRateTest is BaseTest {
    function testSetRewardRateSuccess() public {
        vm.prank(owner);
        staking.setRewardRate(5e18);
        assertEq(staking.rewardRate(), 5e18);
    }

    function testSetRewardRateEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit RewardRateUpdated(5e18);
        vm.prank(owner);
        staking.setRewardRate(5e18);
    }

    function testSetRewardRateOnlyOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        staking.setRewardRate(5e18);
        vm.stopPrank();
    }

    function testSetRewardRateAfterPeriodEnded() public {
        vm.warp(block.timestamp + 31 days);
        vm.startPrank(owner);
        vm.expectRevert("Reward period ended");
        staking.setRewardRate(5e18);
        vm.stopPrank();
    }

    function testSetRewardRateUpdatesPool() public {
        vm.prank(user1);
        stakeToken.approve(address(staking), 100);
        vm.prank(user1);
        staking.stake(100);
        vm.warp(block.timestamp + 1 days);
        uint256 accBefore = staking.accRewardPerShare();
        vm.prank(owner);
        staking.setRewardRate(5e18);
        uint256 accAfter = staking.accRewardPerShare();
        assertGt(accAfter, accBefore);
    }

    function testSetRewardRateZero() public {
        vm.prank(owner);
        staking.setRewardRate(0);
        assertEq(staking.rewardRate(), 0);
    }

    function testSetRewardRateMax() public {
        vm.prank(owner);
        staking.setRewardRate(type(uint128).max);
        assertEq(staking.rewardRate(), type(uint128).max);
    }

    function testSetRewardRateMultipleTimes() public {
        vm.startPrank(owner);
        staking.setRewardRate(2e18);
        assertEq(staking.rewardRate(), 2e18);
        staking.setRewardRate(3e18);
        assertEq(staking.rewardRate(), 3e18);
        staking.setRewardRate(1e18);
        assertEq(staking.rewardRate(), 1e18);
        vm.stopPrank();
    }

    function testSetRewardRateAffectsPendingRewards() public {
        vm.prank(user1);
        stakeToken.approve(address(staking), 100);
        vm.prank(user1);
        staking.stake(100);
        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        staking.setRewardRate(2e18);
        vm.warp(block.timestamp + 1 days);
        uint256 pending = staking.getPendingRewards(user1);
        assertGt(pending, 1 days * 1e18);
    }
}
