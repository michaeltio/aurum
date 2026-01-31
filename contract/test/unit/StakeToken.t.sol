//SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Test} from "forge-std/Test.sol";
import {StakeToken} from "../../contracts/StakeToken.sol";

contract StakeTokenTest is Test {
    StakeToken stakeToken;
    address owner;
    address user;

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        stakeToken = new StakeToken();
    }

    function testNameAndSymbol() public view {
        assertEq(stakeToken.name(), "StakeToken");
        assertEq(stakeToken.symbol(), "SKT");
    }

    function testMintAmountToOwner() public view {
        uint256 decimals = stakeToken.decimals();
        uint256 expectedSupply = 1_000_000 * 10 ** decimals;

        assertEq(stakeToken.totalSupply(), expectedSupply);

        assertEq(stakeToken.balanceOf(owner), expectedSupply);
    }

    function testOtherUserHasZeroBalance() public view {
        assertEq(stakeToken.balanceOf(user), 0);
    }
}
