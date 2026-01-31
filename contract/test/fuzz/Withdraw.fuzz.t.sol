// //SPDX-License-Identifier: MIT

// pragma solidity 0.8.33;

// import {BaseTest} from "../helpers/Base.t.sol";

// contract WithdrawFuzzTest is BaseTest {
//     function setUp() public override {
//         super.setUp();
//     }

//     function testFuzz_Withdraw(
//         uint256 stakeAmount,
//         uint256 withdrawAmount
//     ) public {
//         stakeAmount = bound(stakeAmount, 1, 1e24);
//         withdrawAmount = bound(withdrawAmount, 1, stakeAmount);

//         vm.startPrank(user);
//         stakeToken.approve(address(staking), stakeAmount);
//         staking.stake(stakeAmount);

//         staking.withdraw(withdrawAmount);
//         vm.stopPrank();

//         (uint256 remaining, ) = staking.users(user);
//         assertEq(remaining, stakeAmount - withdrawAmount);
//     }
// }
