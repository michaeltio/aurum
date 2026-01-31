// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Faucet is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public amount;
    uint256 public cooldown;

    mapping(address => uint256) public lastClaim;

    constructor(
        address _token,
        uint256 _amount,
        uint256 _cooldown
    ) Ownable(msg.sender) {
        token = IERC20(_token);
        amount = _amount;
        cooldown = _cooldown;
    }

    function claim() external nonReentrant {
        require(block.timestamp >= lastClaim[msg.sender] + cooldown);
        require(token.balanceOf(address(this)) >= amount);

        lastClaim[msg.sender] = block.timestamp;
        token.safeTransfer(msg.sender, amount);
    }

    function setAmount(uint256 newAmount) external onlyOwner {
        amount = newAmount;
    }

    function setCooldown(uint256 newCooldown) external onlyOwner {
        cooldown = newCooldown;
    }

    function withdraw(uint256 value) external onlyOwner {
        token.safeTransfer(owner(), value);
    }
}
