// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {BaseTest} from "../../helpers/Base.t.sol";

contract StakedBalanceTest is BaseTest {
    function testGetStakedBalanceZeroForNonStaker() public view {
        assertEq(staking.getStakedBalance(user1), 0);
        assertEq(staking.getStakedBalance(address(0)), 0);
        assertEq(staking.getStakedBalance(address(999)), 0);
    }

    function testGetStakedBalanceAfterSingleStake() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        assertEq(staking.getStakedBalance(user1), 100e18);
    }

    function testGetStakedBalanceAfterMultipleStakes() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 300e18);

        staking.stake(100e18);
        assertEq(staking.getStakedBalance(user1), 100e18);

        staking.stake(100e18);
        assertEq(staking.getStakedBalance(user1), 200e18);

        staking.stake(100e18);
        assertEq(staking.getStakedBalance(user1), 300e18);

        vm.stopPrank();
    }

    function testGetStakedBalanceAfterPartialWithdraw() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        staking.withdraw(30e18);
        assertEq(staking.getStakedBalance(user1), 70e18);

        staking.withdraw(20e18);
        assertEq(staking.getStakedBalance(user1), 50e18);

        vm.stopPrank();
    }

    function testGetStakedBalanceAfterFullWithdraw() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        staking.withdraw(100e18);
        assertEq(staking.getStakedBalance(user1), 0);

        vm.stopPrank();
    }

    function testGetStakedBalanceAfterEmergencyWithdraw() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        staking.emergencyWithdraw();
        assertEq(staking.getStakedBalance(user1), 0);

        vm.stopPrank();
    }

    function testGetStakedBalanceMultipleUsersIndependent() public {
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

        assertEq(staking.getStakedBalance(user1), 100e18);
        assertEq(staking.getStakedBalance(user2), 200e18);
        assertEq(staking.getStakedBalance(user3), 300e18);
    }

    function testGetStakedBalanceUnaffectedByTime() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        assertEq(staking.getStakedBalance(user1), 100e18);

        vm.warp(block.timestamp + 1 days);
        assertEq(staking.getStakedBalance(user1), 100e18);

        vm.warp(block.timestamp + 10 days);
        assertEq(staking.getStakedBalance(user1), 100e18);

        vm.warp(block.timestamp + 100 days);
        assertEq(staking.getStakedBalance(user1), 100e18);
    }

    function testGetStakedBalanceUnaffectedByRewardClaim() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimRewards();

        assertEq(staking.getStakedBalance(user1), 100e18);
    }

    function testGetStakedBalanceUnaffectedByOtherUserActions() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakeToken.approve(address(staking), 500e18);
        staking.stake(200e18);
        vm.stopPrank();

        assertEq(staking.getStakedBalance(user1), 100e18);

        vm.prank(user2);
        staking.withdraw(100e18);

        assertEq(staking.getStakedBalance(user1), 100e18);

        vm.prank(user2);
        staking.emergencyWithdraw();

        assertEq(staking.getStakedBalance(user1), 100e18);
    }

    function testGetStakedBalanceAfterStakeWithdrawCycle() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 500e18);

        staking.stake(100e18);
        assertEq(staking.getStakedBalance(user1), 100e18);

        staking.withdraw(50e18);
        assertEq(staking.getStakedBalance(user1), 50e18);

        staking.stake(150e18);
        assertEq(staking.getStakedBalance(user1), 200e18);

        staking.withdraw(200e18);
        assertEq(staking.getStakedBalance(user1), 0);

        staking.stake(100e18);
        assertEq(staking.getStakedBalance(user1), 100e18);

        vm.stopPrank();
    }

    function testGetStakedBalanceWithLargeAmounts() public {
        uint256 largeAmount = 1_000_000_000e18;

        vm.startPrank(owner);
        stakeToken.mint(user1, largeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        stakeToken.approve(address(staking), largeAmount);
        staking.stake(largeAmount);
        vm.stopPrank();

        assertEq(staking.getStakedBalance(user1), largeAmount);
    }

    function testGetStakedBalanceWithSmallAmounts() public {
        uint256 smallAmount = 1;

        vm.startPrank(user1);
        stakeToken.approve(address(staking), smallAmount);
        staking.stake(smallAmount);
        vm.stopPrank();

        assertEq(staking.getStakedBalance(user1), smallAmount);
    }

    function testGetStakedBalanceConsistencyWithUserStruct() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        (uint256 userAmount, ) = staking.users(user1);
        assertEq(staking.getStakedBalance(user1), userAmount);
    }

    function testGetStakedBalanceAfterMultipleFullCycles() public {
        vm.startPrank(user1);
        stakeToken.approve(address(staking), 500e18);

        staking.stake(100e18);
        staking.withdraw(100e18);
        assertEq(staking.getStakedBalance(user1), 0);

        staking.stake(200e18);
        staking.emergencyWithdraw();
        assertEq(staking.getStakedBalance(user1), 0);

        staking.stake(100e18);
        assertEq(staking.getStakedBalance(user1), 100e18);

        vm.stopPrank();
    }

    function testGetStakedBalanceDoesNotRevert() public view {
        staking.getStakedBalance(user1);
        staking.getStakedBalance(address(0));
        staking.getStakedBalance(address(staking));
        staking.getStakedBalance(owner);
    }
}
