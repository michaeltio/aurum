// //SPDX-License-Identifier: MIT

pragma solidity 0.8.33;


// import {BaseTest} from "../helpers/Base.t.sol";

// contract StakeFuzzTest is BaseTest {
//     function setUp() public override {
//         super.setUp();
//     }

//     function testFuzz_Stake(uint256 amount) public {
//         amount = bound(amount, 1, 1e24);

//         vm.startPrank(user);
//         stakeToken.approve(address(staking), amount);
//         staking.stake(amount);
//         vm.stopPrank();

//         (uint256 userAmount, ) = staking.users(user);
//         assertEq(userAmount, amount);
//         assertEq(staking.totalStaked(), amount);
//     }
// }
