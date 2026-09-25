//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {  

    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;
    mapping(address => uint256) public usersBalance;
    mapping(address => uint256) public depositTime;

    event ChangeStakingPeriod(uint256 newPeriod);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimRewards(address indexed user, uint256 rewardAmount);
    event EtherSend(uint256 amount);

    constructor(address _tokenAddress, address _owner, uint256 _stakingPeriod, uint256 _fixedStakingAmount, uint256 _rewardPerPeriod) Ownable(_owner) { 
        stakingToken = _tokenAddress;
        stakingPeriod = _stakingPeriod;
        fixedStakingAmount = _fixedStakingAmount;
        rewardPerPeriod = _rewardPerPeriod;
    }

    function setStakingPeriod(uint256 _stakingPeriod) external onlyOwner { 
        stakingPeriod = _stakingPeriod;

        emit ChangeStakingPeriod(_stakingPeriod);
    }

    function setFixedStakingAmount(uint256 _fixedStakingAmount) external onlyOwner { 
        fixedStakingAmount = _fixedStakingAmount;
    }

    function deposit(uint256 _amount) external { 
        require(_amount == fixedStakingAmount, "Only the fixed staking amount can be staked at a time");
        require(usersBalance[msg.sender] == 0, "You already have an active stake");

        bool success = IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
        require(success, "Failed to transfer staking token");
        usersBalance[msg.sender] += _amount;
        depositTime[msg.sender] = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw() external { 
        require(usersBalance[msg.sender] > 0, "You don't have an active stake to withdraw");

        uint256 amountToWithdraw = usersBalance[msg.sender];
        usersBalance[msg.sender] = 0;

        bool success = IERC20(stakingToken).transfer(msg.sender, amountToWithdraw);
        require(success, "Failed to transfer staking token");
        emit Withdraw(msg.sender, amountToWithdraw);
    }

    function claimRewards() external { 
        require(usersBalance[msg.sender] > 0, "You don't have an active stake to claim rewards from");

        uint256 elapsePeriod = block.timestamp - depositTime[msg.sender];
        require(elapsePeriod >= stakingPeriod, "Staking period has not yet elapsed. Need to wait.");

        depositTime[msg.sender] = block.timestamp;

        (bool success, ) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Failed to send reward");

        emit ClaimRewards(msg.sender, rewardPerPeriod);
    }

    receive() external payable onlyOwner {
        emit EtherSend(msg.value);
    }

    
}