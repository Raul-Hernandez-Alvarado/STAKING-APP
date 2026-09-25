// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0; 

import {Test} from "forge-std/Test.sol"; 
import {StakingApp} from "../src/StakingApp.sol"; 
import {StakingToken} from "../src/StakingToken.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {FailToken} from "./FailToken.sol";

contract StakingAppTest is Test {

    StakingApp stakingApp;
    StakingToken stakingToken;

    address owner = vm.addr(1);
    uint256 stakingPeriord = 1 days;
    uint256 fixedStakingAmount = 10;
    uint256 rewardPerPeriod = 1 ether;


    function setUp() public {
        stakingToken = new StakingToken("Staking Token", "STK");
        stakingApp = new StakingApp(address(stakingToken), owner, 1 days, fixedStakingAmount, rewardPerPeriod);
    }

    function testStakingTokenCorrectDeployed() public view {
        assertEq(stakingApp.stakingToken(), address(stakingToken));
    }

    function testStakingAppCorrectDeployed() public view {
        assertEq(stakingApp.stakingPeriod(), stakingPeriord);
        assertEq(stakingApp.fixedStakingAmount(), fixedStakingAmount);
        assertEq(stakingApp.rewardPerPeriod(), rewardPerPeriod);
    }

    function testSetStakingPeriod(uint256 newPeriod) public {
        vm.prank(owner);

        stakingApp.setStakingPeriod(newPeriod);
        
        assertEq(stakingApp.stakingPeriod(), newPeriod);
    }

    function testSetStakingPeriodNotOwner(uint256 newPeriod) public {
        vm.prank(vm.addr(2));

        vm.expectRevert();
        stakingApp.setStakingPeriod(newPeriod);
    }

    function testSetFixedStakingAmount(uint256 newAmount) public {
        vm.prank(owner);

        stakingApp.setFixedStakingAmount(newAmount);
        
        assertEq(stakingApp.fixedStakingAmount(), newAmount);
    }

    function testSetFixedStakingAmountNotOwner(uint256 newAmount) public {
        vm.prank(vm.addr(2));

        vm.expectRevert();
        stakingApp.setFixedStakingAmount(newAmount);
    }

    function testCorrectContractReceiveEther(uint256 amountToSend) public {
        vm.startPrank(owner);
        vm.deal(owner, amountToSend);

        uint256 balanceBefore = address(stakingApp).balance;
        (bool success, ) = address(stakingApp).call{value: amountToSend}("");
        uint256 balanceAfter = address(stakingApp).balance;
        require(success, "Failed to send Ether to the contract");
        
        assertEq(balanceAfter, balanceBefore + amountToSend);
        vm.stopPrank();
    }

    function testReceiveEtherNotOwner(uint256 amountToSend) public {
        vm.startPrank(vm.addr(2));
        vm.deal(vm.addr(2), amountToSend);

        vm.expectRevert();
        (bool success, ) = address(stakingApp).call{value: amountToSend}("");
        
        vm.stopPrank();
    }

    function testDepositIncorrectAmount(uint256 amount) external {
        if(amount == fixedStakingAmount) {
            return;
        }
        vm.expectRevert("Only the fixed staking amount can be staked at a time");
        stakingApp.deposit(amount);
    }

    function testDepositCorrect() external {
        address user = vm.addr(2);
        vm.startPrank(user);
        assertEq(stakingApp.usersBalance(user), 0);

        uint256 _fixedStakingAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        assertEq(stakingApp.usersBalance(user), _fixedStakingAmount);
        assertEq(stakingApp.depositTime(user), block.timestamp);
    }

    function testUserCannotDepositTwice() external {
        address user = vm.addr(2);
        vm.startPrank(user);

        uint256 _fixedStakingAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(_fixedStakingAmount * 2);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount * 2);

        stakingApp.deposit(_fixedStakingAmount);

        vm.expectRevert("You already have an active stake");
        stakingApp.deposit(_fixedStakingAmount);
    }

    function testWithdrawWithoutActiveStake() external {
        address user = vm.addr(2);
        vm.startPrank(user);
        uint256 userBalanceBefore = stakingApp.usersBalance(user);
        uint256 userBalanceTokenBefore = stakingToken.balanceOf(user);

        vm.expectRevert("You don't have an active stake to withdraw");
        stakingApp.withdraw();

        uint256 userBalanceAfter = stakingApp.usersBalance(user);
        uint256 userBalanceTokenAfter = stakingToken.balanceOf(user);
        assertEq(userBalanceAfter, 0);
        assertEq(userBalanceTokenAfter, userBalanceTokenBefore + userBalanceBefore);
    }

    function testWithdrawCorrect() external {
        address user = vm.addr(2);
        vm.startPrank(user);

        uint256 _fixedStakingAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        uint256 balanceBefore = stakingToken.balanceOf(user);
        stakingApp.withdraw();
        uint256 balanceAfter = stakingToken.balanceOf(user);

        assertEq(balanceAfter, balanceBefore + _fixedStakingAmount);
    }

    function testClaimRewardsWithoutBalance() external {
        address user = vm.addr(2);
        vm.startPrank(user);

        vm.expectRevert("You don't have an active stake to claim rewards from");
        stakingApp.claimRewards();
    }

    function testClaimRewardsIncorrectElapsedTime() external {
        address user = vm.addr(2);
        vm.startPrank(user);

        uint256 _fixedStakingAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        vm.expectRevert("Staking period has not yet elapsed. Need to wait.");
        stakingApp.claimRewards();
    }

    function testClaimRewarWithoutEther() external {
        address user = vm.addr(2);
        vm.startPrank(user);

        uint256 _fixedStakingAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        vm.warp(block.timestamp + stakingApp.stakingPeriod());

        vm.expectRevert("Failed to send reward");
        stakingApp.claimRewards();
    }

    function testClaimRewardsCorrect() external {
        address user = vm.addr(2);
        vm.startPrank(user);

        uint256 _fixedStakingAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        vm.stopPrank();
        vm.startPrank(owner);

        uint256 amountToSend = 10 ether;
        vm.deal(owner, amountToSend);
        (bool success, ) = address(stakingApp).call{value: amountToSend}("");
        require(success, "Failed to send Ether to the contract");

        vm.stopPrank();
        vm.startPrank(user);
        vm.warp(block.timestamp + stakingApp.stakingPeriod());

        uint256 balanceBefore = address(user).balance;
        stakingApp.claimRewards();
        uint256 balanceAfter = address(user).balance;
        uint256 elapsedPeriod = stakingApp.depositTime(user);

        assertEq(balanceAfter, balanceBefore + stakingApp.rewardPerPeriod());
        assertEq(elapsedPeriod, block.timestamp);
    }

    function testDepositTransferFromFails() external {
        address user = vm.addr(2);

        uint256 _fixedStakingAmount = stakingApp.fixedStakingAmount();
        FailToken failToken = new FailToken();
        StakingApp appWithFailToken = new StakingApp(address(failToken), owner, 1 days, fixedStakingAmount, rewardPerPeriod);

        vm.startPrank(user);
        vm.expectRevert("Failed to transfer staking token");
        appWithFailToken.deposit(_fixedStakingAmount);

        vm.stopPrank();
    }

    function testWithdrawTransferFails() external {
        address user = vm.addr(2);

        uint256 _fixedStakingAmount = stakingApp.fixedStakingAmount();
        FailToken failToken = new FailToken();
        StakingApp appWithFailToken = new StakingApp(address(failToken), owner, 1 days, fixedStakingAmount, rewardPerPeriod);

        vm.startPrank(user);
        appWithFailToken.deposit(_fixedStakingAmount);

        vm.expectRevert("Failed to transfer staking token");
        appWithFailToken.withdraw();

        vm.stopPrank();
    }

}