// SPDX-License-Identifier: MIT

// pragma solidity 0.8.33;

import {BaseTest} from "../../helpers/Base.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MaliciousReentrancyAttacker
 * @notice Malicious contract that attempts reentrancy attacks on Staking contract
 * @dev Simulates various attack vectors through callback functions
 */
contract MaliciousReentrancyAttacker {
    address public stakingContract;
    address public owner;

    enum AttackType {
        WITHDRAW_ON_WITHDRAW,
        CLAIM_ON_WITHDRAW,
        STAKE_ON_WITHDRAW,
        EMERGENCY_ON_WITHDRAW,
        WITHDRAW_ON_CLAIM,
        CLAIM_ON_CLAIM,
        WITHDRAW_ON_EMERGENCY,
        CLAIM_ON_EMERGENCY,
        STAKE_ON_CLAIM,
        EMERGENCY_ON_CLAIM
    }

    AttackType public currentAttack;
    bool public attacking;
    uint256 public attackCount;
    uint256 public maxAttacks = 2;

    constructor(address _stakingContract) {
        stakingContract = _stakingContract;
        owner = msg.sender;
    }

    function setAttackType(AttackType _type) external {
        require(msg.sender == owner, "Not owner");
        currentAttack = _type;
    }

    function setMaxAttacks(uint256 _max) external {
        require(msg.sender == owner, "Not owner");
        maxAttacks = _max;
    }

    function resetAttackCount() external {
        require(msg.sender == owner, "Not owner");
        attackCount = 0;
    }

    function initiateStake(uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        attacking = true;
        attackCount = 0;
        (bool success, ) = stakingContract.call(
            abi.encodeWithSignature("stake(uint256)", amount)
        );
        attacking = false;
        require(success, "Stake failed");
    }

    function initiateWithdraw(uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        attacking = true;
        attackCount = 0;
        (bool success, ) = stakingContract.call(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );
        attacking = false;
        require(success, "Withdraw failed");
    }

    function initiateClaim() external {
        require(msg.sender == owner, "Not owner");
        attacking = true;
        attackCount = 0;
        (bool success, ) = stakingContract.call(
            abi.encodeWithSignature("claimRewards()")
        );
        attacking = false;
        require(success, "Claim failed");
    }

    function initiateEmergencyWithdraw() external {
        require(msg.sender == owner, "Not owner");
        attacking = true;
        attackCount = 0;
        (bool success, ) = stakingContract.call(
            abi.encodeWithSignature("emergencyWithdraw()")
        );
        attacking = false;
        require(success, "Emergency withdraw failed");
    }

    // Fallback function triggered when receiving ETH/tokens
    receive() external payable {
        if (attacking && attackCount < maxAttacks) {
            attackCount++;
            executeReentrancy();
        }
    }

    fallback() external payable {
        if (attacking && attackCount < maxAttacks) {
            attackCount++;
            executeReentrancy();
        }
    }

    function executeReentrancy() internal {
        if (currentAttack == AttackType.WITHDRAW_ON_WITHDRAW) {
            stakingContract.call(
                abi.encodeWithSignature("withdraw(uint256)", 10e18)
            );
        } else if (currentAttack == AttackType.CLAIM_ON_WITHDRAW) {
            stakingContract.call(abi.encodeWithSignature("claimRewards()"));
        } else if (currentAttack == AttackType.STAKE_ON_WITHDRAW) {
            stakingContract.call(
                abi.encodeWithSignature("stake(uint256)", 10e18)
            );
        } else if (currentAttack == AttackType.EMERGENCY_ON_WITHDRAW) {
            stakingContract.call(
                abi.encodeWithSignature("emergencyWithdraw()")
            );
        } else if (currentAttack == AttackType.WITHDRAW_ON_CLAIM) {
            stakingContract.call(
                abi.encodeWithSignature("withdraw(uint256)", 10e18)
            );
        } else if (currentAttack == AttackType.CLAIM_ON_CLAIM) {
            stakingContract.call(abi.encodeWithSignature("claimRewards()"));
        } else if (currentAttack == AttackType.WITHDRAW_ON_EMERGENCY) {
            stakingContract.call(
                abi.encodeWithSignature("withdraw(uint256)", 10e18)
            );
        } else if (currentAttack == AttackType.CLAIM_ON_EMERGENCY) {
            stakingContract.call(abi.encodeWithSignature("claimRewards()"));
        } else if (currentAttack == AttackType.STAKE_ON_CLAIM) {
            stakingContract.call(
                abi.encodeWithSignature("stake(uint256)", 10e18)
            );
        } else if (currentAttack == AttackType.EMERGENCY_ON_CLAIM) {
            stakingContract.call(
                abi.encodeWithSignature("emergencyWithdraw()")
            );
        }
    }
}

/**
 * @title MaliciousERC20
 * @notice Malicious ERC20 token that triggers callbacks during transfer
 * @dev Used to simulate ERC777-like hooks for reentrancy testing
 */
contract MaliciousERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public attacker;
    bool public triggerCallback;

    string public name = "Malicious Token";
    string public symbol = "MAL";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function setAttacker(address _attacker) external {
        attacker = _attacker;
    }

    function setTriggerCallback(bool _trigger) external {
        triggerCallback = _trigger;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        return _transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);

        // Trigger callback to attacker contract when transferring to it
        if (triggerCallback && to == attacker) {
            (bool success, ) = attacker.call("");
            require(success, "Callback failed");
        }

        return true;
    }
}

/**
 * @title ReentrancyTest
 * @notice Comprehensive test suite for reentrancy protection
 * @dev Tests all critical functions with nonReentrant modifier
 */
contract ReentrancyTest is BaseTest {
    MaliciousReentrancyAttacker public attacker;

    function setUp() public override {
        super.setUp();
        attacker = new MaliciousReentrancyAttacker(address(staking));

        // Fund the attacker contract
        vm.startPrank(owner);
        stakeToken.mint(address(attacker), 1000e18);
        vm.stopPrank();

        // Approve staking contract
        vm.prank(address(attacker));
        stakeToken.approve(address(staking), type(uint256).max);
    }

    // ============ WITHDRAW REENTRANCY TESTS ============

    function test_RevertIf_ReentrancyWithdrawOnWithdraw() public {
        // Setup: stake tokens first
        vm.prank(user1);
        stakeToken.approve(address(staking), 100e18);
        vm.prank(user1);
        staking.stake(100e18);

        // Transfer user1's stake to attacker for testing
        vm.prank(owner);
        stakeToken.mint(address(attacker), 100e18);

        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        // Set attack type
        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_WITHDRAW
        );

        // Attempt reentrancy - should fail due to ReentrancyGuard
        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateWithdraw(50e18);
    }

    function test_RevertIf_ReentrancyClaimOnWithdraw() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.CLAIM_ON_WITHDRAW
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateWithdraw(50e18);
    }

    function test_RevertIf_ReentrancyStakeOnWithdraw() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.STAKE_ON_WITHDRAW
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateWithdraw(50e18);
    }

    function test_RevertIf_ReentrancyEmergencyOnWithdraw() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.EMERGENCY_ON_WITHDRAW
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateWithdraw(50e18);
    }

    // ============ CLAIM REWARDS REENTRANCY TESTS ============

    function test_RevertIf_ReentrancyWithdrawOnClaim() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_CLAIM
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateClaim();
    }

    function test_RevertIf_ReentrancyClaimOnClaim() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.CLAIM_ON_CLAIM
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateClaim();
    }

    function test_RevertIf_ReentrancyStakeOnClaim() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.STAKE_ON_CLAIM
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateClaim();
    }

    function test_RevertIf_ReentrancyEmergencyOnClaim() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.EMERGENCY_ON_CLAIM
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateClaim();
    }

    // ============ EMERGENCY WITHDRAW REENTRANCY TESTS ============

    function test_RevertIf_ReentrancyWithdrawOnEmergencyWithdraw() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_EMERGENCY
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateEmergencyWithdraw();
    }

    function test_RevertIf_ReentrancyClaimOnEmergencyWithdraw() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.CLAIM_ON_EMERGENCY
        );

        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateEmergencyWithdraw();
    }

    // ============ CROSS-FUNCTION REENTRANCY TESTS ============

    function test_ReentrancyProtectionAcrossAllFunctions() public {
        // Stake tokens
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        // Test that no combination of reentrancy works
        MaliciousReentrancyAttacker.AttackType[10] memory attacks = [
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_WITHDRAW,
            MaliciousReentrancyAttacker.AttackType.CLAIM_ON_WITHDRAW,
            MaliciousReentrancyAttacker.AttackType.STAKE_ON_WITHDRAW,
            MaliciousReentrancyAttacker.AttackType.EMERGENCY_ON_WITHDRAW,
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_CLAIM,
            MaliciousReentrancyAttacker.AttackType.CLAIM_ON_CLAIM,
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_EMERGENCY,
            MaliciousReentrancyAttacker.AttackType.CLAIM_ON_EMERGENCY,
            MaliciousReentrancyAttacker.AttackType.STAKE_ON_CLAIM,
            MaliciousReentrancyAttacker.AttackType.EMERGENCY_ON_CLAIM
        ];

        for (uint256 i = 0; i < attacks.length; i++) {
            attacker.resetAttackCount();

            // Re-stake if needed
            uint256 balance = staking.getStakedBalance(address(attacker));
            if (balance == 0) {
                vm.prank(address(attacker));
                staking.stake(100e18);
                vm.warp(block.timestamp + 1 hours);
            }

            attacker.setAttackType(attacks[i]);

            // All attacks should fail
            vm.prank(user1);
            if (i < 4) {
                vm.expectRevert();
                attacker.initiateWithdraw(10e18);
            } else if (i < 6 || i == 8 || i == 9) {
                vm.expectRevert();
                attacker.initiateClaim();
            } else {
                vm.expectRevert();
                attacker.initiateEmergencyWithdraw();
            }
        }
    }

    // ============ LEGITIMATE USE AFTER FAILED REENTRANCY ============

    function test_LegitimateWithdrawAfterFailedReentrancy() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_WITHDRAW
        );

        // Failed reentrancy attempt
        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateWithdraw(50e18);

        // Legitimate withdrawal should still work
        vm.prank(address(attacker));
        staking.withdraw(50e18);

        assertEq(staking.getStakedBalance(address(attacker)), 50e18);
    }

    function test_LegitimateClaimAfterFailedReentrancy() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        uint256 pendingBefore = staking.getPendingRewards(address(attacker));

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.CLAIM_ON_CLAIM
        );

        // Failed reentrancy attempt
        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateClaim();

        // Legitimate claim should still work
        uint256 balanceBefore = rewardToken.balanceOf(address(attacker));
        vm.prank(address(attacker));
        staking.claimRewards();
        uint256 balanceAfter = rewardToken.balanceOf(address(attacker));

        assertGt(balanceAfter - balanceBefore, 0);
        assertApproxEqRel(balanceAfter - balanceBefore, pendingBefore, 0.01e18);
    }

    function test_LegitimateEmergencyWithdrawAfterFailedReentrancy() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_EMERGENCY
        );

        // Failed reentrancy attempt
        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateEmergencyWithdraw();

        // Legitimate emergency withdrawal should still work
        uint256 balanceBefore = stakeToken.balanceOf(address(attacker));
        vm.prank(address(attacker));
        staking.emergencyWithdraw();
        uint256 balanceAfter = stakeToken.balanceOf(address(attacker));

        assertEq(balanceAfter - balanceBefore, 100e18);
        assertEq(staking.getStakedBalance(address(attacker)), 0);
    }

    // ============ MULTIPLE REENTRANCY ATTEMPTS ============

    function test_RevertIf_MultipleReentrancyAttempts() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_WITHDRAW
        );
        attacker.setMaxAttacks(5); // Try to reenter multiple times

        // Even with multiple attempts, should fail
        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateWithdraw(10e18);

        // Verify attack was blocked at first attempt
        assertLt(attacker.attackCount(), 2);
    }

    // ============ STATE CONSISTENCY TESTS ============

    function test_StateConsistencyAfterFailedReentrancy() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        uint256 totalStakedBefore = staking.totalStaked();
        uint256 attackerBalanceBefore = staking.getStakedBalance(
            address(attacker)
        );

        vm.warp(block.timestamp + 1 hours);

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.WITHDRAW_ON_WITHDRAW
        );

        // Failed reentrancy
        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateWithdraw(50e18);

        // State should remain unchanged
        assertEq(staking.totalStaked(), totalStakedBefore);
        assertEq(
            staking.getStakedBalance(address(attacker)),
            attackerBalanceBefore
        );
    }

    function test_NoRewardLeakageFromFailedReentrancy() public {
        vm.prank(address(attacker));
        staking.stake(100e18);

        vm.warp(block.timestamp + 1 hours);

        uint256 rewardBalanceBefore = rewardToken.balanceOf(address(attacker));

        attacker.setAttackType(
            MaliciousReentrancyAttacker.AttackType.CLAIM_ON_CLAIM
        );

        // Failed reentrancy
        vm.prank(user1);
        vm.expectRevert();
        attacker.initiateClaim();

        // No rewards should have been transferred
        assertEq(rewardToken.balanceOf(address(attacker)), rewardBalanceBefore);
    }
}
