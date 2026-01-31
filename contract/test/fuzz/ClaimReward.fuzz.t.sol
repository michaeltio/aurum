//SPDX-License-Identifier: MIT

pragma solidity 0.8.33;


import {BaseTest} from "../helpers/Base.t.sol";

contract ClaimRewardFuzzTest is BaseTest {
    // function testFuzz_ClaimRewards(uint256 amount, uint256 timeSkip) public {
    //     amount = bound(amount, 1, 1e24);
    //     timeSkip = bound(timeSkip, 1, 30 days);
    //     vm.startPrank(user1);
    //     stakeToken.approve(address(staking), amount);
    //     staking.stake(amount);
    //     vm.stopPrank();
    //     vm.warp(block.timestamp + timeSkip);
    //     vm.prank(user1);
    //     staking.claimRewards();
    //     (, uint256 rewardDebt) = staking.users(user1);
    //     assertGt(rewardDebt, 0);
    // }
}
