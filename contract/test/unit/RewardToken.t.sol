//SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Test} from "forge-std/Test.sol";
import {RewardToken} from "../../contracts/RewardToken.sol";

contract RewardTokenTest is Test {
    RewardToken rewardToken;
    address owner;
    address user;

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        rewardToken = new RewardToken();
    }

    function testNameAndSymbol() public view {
        assertEq(rewardToken.name(), "RewardToken");
        assertEq(rewardToken.symbol(), "RWT");
    }

    function testMintAmountToOwner() public view {
        uint256 decimals = rewardToken.decimals();
        uint256 expectedSupply = 500_000 * 10 ** decimals;

        assertEq(rewardToken.totalSupply(), expectedSupply);

        assertEq(rewardToken.balanceOf(owner), expectedSupply);
    }

    function testOtherUserHasZeroBalance() public view {
        assertEq(rewardToken.balanceOf(user), 0);
    }
}
