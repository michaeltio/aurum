// SPDX-License-Identifier: MIT
// accRewardPerShare: accumulated rewards per staked token (scaled by 1e12)
// rewardRate: reward tokens distributed per second
// rewardEndTime: timestamp when reward stops accumulating

pragma solidity 0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;
    IERC20 public rewardToken;

    struct User {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => User) public users;

    uint256 public rewardRate;
    uint256 public lastRewardTime;
    uint256 public totalStaked;
    uint256 public accRewardPerShare;
    uint256 public rewardEndTime;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event RewardsFunded(uint256 amount);
    event RewardEndTimeUpdated(uint256 newEndTime);

    constructor(address _stakeToken, address _rewardToken) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
    }

    function stake(uint256 amount) public nonReentrant {
        require(block.timestamp < rewardEndTime, "Staking period ended");
        require(amount > 0, "Cannot stake zero tokens");

        User storage user = users[msg.sender];

        updatePool();

        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare) /
                1e12 -
                user.rewardDebt;

            if (pending > 0) {
                _safeRewardTransfer(msg.sender, pending);
                emit RewardClaimed(msg.sender, pending);
            }
        }

        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        user.amount += amount;
        totalStaked += amount;

        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        User storage user = users[msg.sender];
        require(amount > 0, "Cannot Withdraw 0 Amount");
        require(user.amount >= amount, "Not enough staked");

        updatePool();

        uint256 pending = (user.amount * accRewardPerShare) /
            1e12 -
            user.rewardDebt;

        if (pending > 0) {
            _safeRewardTransfer(msg.sender, pending);
            emit RewardClaimed(msg.sender, pending);
        }

        user.amount -= amount;
        totalStaked -= amount;

        stakeToken.safeTransfer(msg.sender, amount);

        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() public nonReentrant {
        User storage user = users[msg.sender];

        updatePool();

        uint256 pending = (user.amount * accRewardPerShare) /
            1e12 -
            user.rewardDebt;

        require(pending > 0, "No rewards");

        _safeRewardTransfer(msg.sender, pending);
        emit RewardClaimed(msg.sender, pending);

        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
    }

    function setRewardRate(uint256 _rate) public onlyOwner {
        require(block.timestamp < rewardEndTime, "Reward period ended");
        updatePool();
        rewardRate = _rate;
        emit RewardRateUpdated(_rate);
    }

    function getStakedBalance(address user) public view returns (uint256) {
        return users[user].amount;
    }

    function getPendingRewards(address _user) external view returns (uint256) {
        User storage user = users[_user];
        uint256 tempAcc = accRewardPerShare;
        uint256 currentTime = block.timestamp;

        if (currentTime > rewardEndTime) {
            currentTime = rewardEndTime;
        }

        if (currentTime > lastRewardTime && totalStaked != 0) {
            uint256 timePassed = currentTime - lastRewardTime;
            uint256 reward = timePassed * rewardRate;
            tempAcc += (reward * 1e12) / totalStaked;
        }

        return (user.amount * tempAcc) / 1e12 - user.rewardDebt;
    }

    function emergencyWithdraw() public nonReentrant {
        User storage user = users[msg.sender];
        uint256 amount = user.amount;
        require(amount > 0, "Nothing to withdraw");

        user.amount = 0;
        user.rewardDebt = 0;
        totalStaked -= amount;

        stakeToken.safeTransfer(msg.sender, amount);

        emit EmergencyWithdrawn(msg.sender, amount);
    }

    function updatePool() internal {
        uint256 currentTime = block.timestamp;

        if (currentTime <= lastRewardTime) return;

        if (currentTime > rewardEndTime) {
            currentTime = rewardEndTime;
        }

        if (currentTime <= lastRewardTime) return;

        if (totalStaked == 0) {
            lastRewardTime = currentTime;
            return;
        }

        uint256 timePassed = currentTime - lastRewardTime;
        uint256 reward = timePassed * rewardRate;

        accRewardPerShare += (reward * 1e12) / totalStaked;
        lastRewardTime = currentTime;
    }

    function fundRewards(uint256 amount) external onlyOwner {
        require(amount > 0, "Zero amount");
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardsFunded(amount);
    }

    function _safeRewardTransfer(address to, uint256 amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }
        if (amount > 0) {
            rewardToken.safeTransfer(to, amount);
        }
    }

    function setRewardEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > block.timestamp, "Invalid end time");
        updatePool();
        rewardEndTime = _endTime;
        emit RewardEndTimeUpdated(_endTime);
    }
}
