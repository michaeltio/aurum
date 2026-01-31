// //SPDX-License-Identifier: MIT

//pragma solidity 0.8.33;


// import {BaseTest} from "../helpers/Base.t.sol";

// contract EmergencyWithdrawFuzzTest is BaseTest {
//     function setUp() public override {
//         super.setUp();
//     }

//     function testFuzz_EmergencyWithdraw(uint256 amount) public {
//         amount = bound(amount, 1, 1e24);

//         vm.startPrank(user);
//         stakeToken.approve(address(staking), amount);
//         staking.stake(amount);
//         staking.emergencyWithdraw();
//         vm.stopPrank();

//         (uint256 userAmount, uint256 rewardDebt) = staking.users(user);
//         assertEq(userAmount, 0);
//         assertEq(rewardDebt, 0);
//     }
// }
