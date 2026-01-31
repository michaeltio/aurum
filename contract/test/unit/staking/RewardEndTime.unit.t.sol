//SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {BaseTest} from "../../helpers/Base.t.sol";

contract RewardEndTimeTest is BaseTest {
    function testSetRewardEndTimeSuccess() public {
        uint256 newEndTime = block.timestamp + 60 days;
        vm.prank(owner);
        staking.setRewardEndTime(newEndTime);
        assertEq(staking.rewardEndTime(), newEndTime);
    }

    function testSetRewardEndTimeOnlyOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        staking.setRewardEndTime(block.timestamp + 60 days);
        vm.stopPrank();
    }

    function testSetRewardEndTimeInPast() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid end time");
        staking.setRewardEndTime(block.timestamp - 1);
        vm.stopPrank();
    }

    function testSetRewardEndTimeUpdatesPool() public {
        vm.prank(user1);
        stakeToken.approve(address(staking), 100);
        vm.prank(user1);
        staking.stake(100);
        vm.warp(block.timestamp + 1 days);
        uint256 accBefore = staking.accRewardPerShare();
        vm.prank(owner);
        staking.setRewardEndTime(block.timestamp + 60 days);
        uint256 accAfter = staking.accRewardPerShare();
        assertGt(accAfter, accBefore);
    }

    function testSetRewardEndTimeExtendsPeriod() public {
        uint256 newEndTime = block.timestamp + 90 days;
        vm.prank(owner);
        staking.setRewardEndTime(newEndTime);
        assertEq(staking.rewardEndTime(), newEndTime);
    }

    function testSetRewardEndTimeMultipleTimes() public {
        vm.startPrank(owner);
        staking.setRewardEndTime(block.timestamp + 40 days);
        staking.setRewardEndTime(block.timestamp + 50 days);
        staking.setRewardEndTime(block.timestamp + 60 days);
        assertEq(staking.rewardEndTime(), block.timestamp + 60 days);
        vm.stopPrank();
    }

    function testSetRewardEndTimeBlocksStakingAfter() public {
        vm.prank(owner);
        staking.setRewardEndTime(block.timestamp + 1 days);
        vm.warp(block.timestamp + 2 days);
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100);
        vm.expectRevert("Staking period ended");
        staking.stake(100);
        vm.stopPrank();
    }

    function testSetRewardEndTimeAffectsRewardCalculation() public {
        vm.prank(user1);
        stakeToken.approve(address(staking), 100);
        vm.prank(user1);
        staking.stake(100);
        vm.prank(owner);
        staking.setRewardEndTime(block.timestamp + 10 days);
        vm.warp(block.timestamp + 20 days);
        uint256 pending = staking.getPendingRewards(user1);
        uint256 expectedMax = 10 days * 1e18;
        assertApproxEqRel(pending, expectedMax, 0.01e18);
    }
}
