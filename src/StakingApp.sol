//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {  

    error InvalidStakingAmount();
    error ActiveStakeExists();
    error TransferFailed();
    error NoActiveStake();
    error StakingPeriodNotElapsed();
    error RewardTransferFailed();

    address public stakingToken;
    uint96 public fixedStakingAmount;
    uint64 public stakingPeriod;
    uint128 public rewardPerPeriod;
    mapping(address => uint256) public usersBalance;
    mapping(address => uint256) public depositTime;

    event ChangeStakingPeriod(uint256 newPeriod);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimRewards(address indexed user, uint256 rewardAmount);
    event EtherSend(uint256 amount);

    constructor (
        address _tokenAddress, 
        address _owner, 
        uint64 _stakingPeriod, 
        uint96 _fixedStakingAmount, 
        uint128 _rewardPerPeriod
    ) Ownable(_owner) {  
        stakingToken = _tokenAddress;
        stakingPeriod = _stakingPeriod;
        fixedStakingAmount = _fixedStakingAmount;
        rewardPerPeriod = _rewardPerPeriod;
    }

    function setStakingPeriod(uint64 _stakingPeriod) external onlyOwner { 
        stakingPeriod = _stakingPeriod;
        emit ChangeStakingPeriod(_stakingPeriod);
    }

    function setFixedStakingAmount(uint96 _fixedStakingAmount) external onlyOwner { 
        fixedStakingAmount = _fixedStakingAmount;
    }

    function deposit(uint96 _amount) external { 
        if (_amount != fixedStakingAmount) revert InvalidStakingAmount();
        if (usersBalance[msg.sender] != 0) revert ActiveStakeExists();

        bool success = IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TransferFailed();

        usersBalance[msg.sender] = _amount;
        depositTime[msg.sender] = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw() external { 
        uint256 balance = usersBalance[msg.sender];
        if (balance == 0) revert NoActiveStake();

        usersBalance[msg.sender] = 0;

        bool success = IERC20(stakingToken).transfer(msg.sender, balance);
        if (!success) revert TransferFailed();
        
        emit Withdraw(msg.sender, balance);
    }

    function claimRewards() external { 
        if (usersBalance[msg.sender] == 0) revert NoActiveStake();

        uint256 elapsePeriod = block.timestamp - depositTime[msg.sender];
        if (elapsePeriod < stakingPeriod) revert StakingPeriodNotElapsed();

        uint256 periods = elapsePeriod / stakingPeriod; 
        uint256 totalReward = periods * rewardPerPeriod;

        depositTime[msg.sender] += periods * stakingPeriod;

        (bool success, ) = msg.sender.call{value: totalReward}("");
        if (!success) revert RewardTransferFailed();

        emit ClaimRewards(msg.sender, totalReward);
    }

    receive() external payable {
        emit EtherSend(msg.value);
    }

    
}