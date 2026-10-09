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

    address owner = makeAddr("owner");
    uint64 stakingPeriord = 1 days;
    uint96 fixedStakingAmount = 10;
    uint128 rewardPerPeriod = 1 ether;

    function setUp() public {
        stakingToken = new StakingToken("Staking Token", "STK");
        stakingApp = new StakingApp(address(stakingToken), owner, stakingPeriord, fixedStakingAmount, rewardPerPeriod);
    }

    function testStakingTokenCorrectDeployed() public view {
        assertEq(stakingApp.stakingToken(), address(stakingToken));
    }

    function testStakingAppCorrectDeployed() public view {
        assertEq(stakingApp.stakingPeriod(), stakingPeriord);
        assertEq(stakingApp.fixedStakingAmount(), fixedStakingAmount);
        assertEq(stakingApp.rewardPerPeriod(), rewardPerPeriod);
    }

    function testSetStakingPeriod(uint64 newPeriod) public {
        vm.prank(owner);

        stakingApp.setStakingPeriod(newPeriod);
        
        assertEq(stakingApp.stakingPeriod(), newPeriod);
    }

    function testSetStakingPeriodNotOwner(uint64 newPeriod) public {
        address user = makeAddr("user2");
        vm.prank(user);

        vm.expectRevert();
        stakingApp.setStakingPeriod(newPeriod);
    }

    function testSetFixedStakingAmount(uint96 newAmount) public {
        vm.prank(owner);

        stakingApp.setFixedStakingAmount(newAmount);
        
        assertEq(stakingApp.fixedStakingAmount(), newAmount);
    }

    function testSetFixedStakingAmountNotOwner(uint96 newAmount) public {
        address user = makeAddr("user2");
        vm.prank(user);

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

    function testReceiveEtherAnyUser(uint256 amountToSend) public {
        address user = makeAddr("user2");
        vm.startPrank(user);
        vm.deal(user, amountToSend);

        uint256 balanceBefore = address(stakingApp).balance;
        (bool success, ) = address(stakingApp).call{value: amountToSend}("");
        uint256 balanceAfter = address(stakingApp).balance;
        require(success, "Failed to send Ether to the contract");
        
        assertEq(balanceAfter, balanceBefore + amountToSend);
        vm.stopPrank();
    }

    function testDepositIncorrectAmount(uint96 amount) external {
        if(amount == fixedStakingAmount) {
            return;
        }
        vm.expectRevert(StakingApp.InvalidStakingAmount.selector);
        stakingApp.deposit(amount);
    }

    function testDepositCorrect() external {
        address user = makeAddr("user");
        vm.startPrank(user);
        assertEq(stakingApp.usersBalance(user), 0);

        uint96 _fixedStakingAmount = uint96(stakingApp.fixedStakingAmount());
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        assertEq(stakingApp.usersBalance(user), _fixedStakingAmount);
        assertEq(stakingApp.depositTime(user), block.timestamp);
    }

    function testUserCannotDepositTwice() external {
        address user = makeAddr("user");
        vm.startPrank(user);

        uint96 _fixedStakingAmount = uint96(stakingApp.fixedStakingAmount());
        stakingToken.mint(_fixedStakingAmount * 2);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount * 2);

        stakingApp.deposit(_fixedStakingAmount);

        vm.expectRevert(StakingApp.ActiveStakeExists.selector);
        stakingApp.deposit(_fixedStakingAmount);
    }

    function testWithdrawWithoutActiveStake() external {
        address user = makeAddr("user");
        vm.startPrank(user);
        uint256 userBalanceBefore = stakingApp.usersBalance(user);
        uint256 userBalanceTokenBefore = stakingToken.balanceOf(user);

        vm.expectRevert(StakingApp.NoActiveStake.selector);
        stakingApp.withdraw();

        uint256 userBalanceAfter = stakingApp.usersBalance(user);
        uint256 userBalanceTokenAfter = stakingToken.balanceOf(user);
        assertEq(userBalanceAfter, 0);
        assertEq(userBalanceTokenAfter, userBalanceTokenBefore + userBalanceBefore);
    }

    function testWithdrawCorrect() external {
        address user = makeAddr("user");
        vm.startPrank(user);

        uint96 _fixedStakingAmount = uint96(stakingApp.fixedStakingAmount());
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        uint256 balanceBefore = stakingToken.balanceOf(user);
        stakingApp.withdraw();
        uint256 balanceAfter = stakingToken.balanceOf(user);

        assertEq(balanceAfter, balanceBefore + _fixedStakingAmount);
    }

    function testClaimRewardsWithoutBalance() external {
        address user = makeAddr("user");
        vm.startPrank(user);

        vm.expectRevert(StakingApp.NoActiveStake.selector);
        stakingApp.claimRewards();
    }

    function testClaimRewardsIncorrectElapsedTime() external {
        address user = makeAddr("user");
        vm.startPrank(user);

        uint96 _fixedStakingAmount = uint96(stakingApp.fixedStakingAmount());
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        vm.expectRevert(StakingApp.StakingPeriodNotElapsed.selector);
        stakingApp.claimRewards();
    }

    function testClaimRewarWithoutEther() external {
        address user = makeAddr("user");
        vm.startPrank(user);

        uint96 _fixedStakingAmount = uint96(stakingApp.fixedStakingAmount());
        stakingToken.mint(_fixedStakingAmount);

        stakingToken.approve(address(stakingApp), _fixedStakingAmount);

        stakingApp.deposit(_fixedStakingAmount);

        vm.warp(block.timestamp + stakingApp.stakingPeriod());

        vm.expectRevert(StakingApp.RewardTransferFailed.selector);
        stakingApp.claimRewards();
    }

    function testClaimRewardsCorrect() external {
        address user = makeAddr("user");
        vm.startPrank(user);

        uint96 _fixedStakingAmount = uint96(stakingApp.fixedStakingAmount());
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
        address user = makeAddr("user");

        uint96 _fixedStakingAmount = uint96(stakingApp.fixedStakingAmount());
        FailToken failToken = new FailToken();
        StakingApp appWithFailToken = new StakingApp(address(failToken), owner, stakingPeriord, fixedStakingAmount, rewardPerPeriod);

        vm.startPrank(user);
        vm.expectRevert(StakingApp.TransferFailed.selector);
        appWithFailToken.deposit(_fixedStakingAmount);

        vm.stopPrank();
    }

    function testWithdrawTransferFails() external {
        address user = makeAddr("user");

        uint96 _fixedStakingAmount = uint96(stakingApp.fixedStakingAmount());
        FailToken failToken = new FailToken();
        StakingApp appWithFailToken = new StakingApp(address(failToken), owner, stakingPeriord, fixedStakingAmount, rewardPerPeriod);

        vm.startPrank(user);
        
        // Se asume que en FailToken se simula el exito del deposito para que la prueba de withdraw avance hasta el revert correcto
        vm.mockCall(address(failToken), abi.encodeWithSelector(IERC20.transferFrom.selector), abi.encode(true));
        appWithFailToken.deposit(_fixedStakingAmount);
        vm.clearMockedCalls();

        vm.expectRevert(StakingApp.TransferFailed.selector);
        appWithFailToken.withdraw();

        vm.stopPrank();
    }

}