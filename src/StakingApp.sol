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

    /**
    * @notice Initializes the staking contract with token, owner, and staking parameters
    * @param _tokenAddress The address of the ERC20 token used for staking
    * @param _owner The address of the contract owner
    * @param _stakingPeriod The time in seconds required to elapse for a reward period
    * @param _fixedStakingAmount The exact amount of tokens required to stake
    * @param _rewardPerPeriod The amount of ETH rewarded per staking period
    */
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

    /**
    * @notice Updates the required time for a staking period
    * @param _stakingPeriod The new staking period in seconds
    */
    function setStakingPeriod(uint64 _stakingPeriod) external onlyOwner { 
        stakingPeriod = _stakingPeriod;
        emit ChangeStakingPeriod(_stakingPeriod);
    }

    /**
    * @notice Updates the fixed token amount required to stake
    * @param _fixedStakingAmount The new fixed staking amount
    */
    function setFixedStakingAmount(uint96 _fixedStakingAmount) external onlyOwner { 
        fixedStakingAmount = _fixedStakingAmount;
    }

    /**
    * @notice Deposits the fixed staking amount into the contract
    * @param _amount The amount of tokens to stake
    */
    function deposit(uint96 _amount) external { 
        if (_amount != fixedStakingAmount) revert InvalidStakingAmount();
        if (usersBalance[msg.sender] != 0) revert ActiveStakeExists();

        bool success = IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TransferFailed();

        usersBalance[msg.sender] = _amount;
        depositTime[msg.sender] = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    /**
    * @notice Withdraws the staked tokens
    * @dev Withdrawing before claiming rewards will forfeit any pending rewards
    */
    function withdraw() external { 
        uint256 balance = usersBalance[msg.sender];
        if (balance == 0) revert NoActiveStake();

        usersBalance[msg.sender] = 0;

        bool success = IERC20(stakingToken).transfer(msg.sender, balance);
        if (!success) revert TransferFailed();
        
        emit Withdraw(msg.sender, balance);
    }

    /**
    * @notice Claims the accumulated ETH rewards based on the elapsed staking periods
    */
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

    /**
    * @notice Allows the contract to receive ETH to fund the reward pool
    */
    receive() external payable {
        emit EtherSend(msg.value);
    }
}