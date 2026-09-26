// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0; 

import {Test} from "forge-std/Test.sol"; 
import {StakingToken} from "../src/StakingToken.sol"; 
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingTokenTest is Test {

    StakingToken stakingToken;
    string name = "Staking Token"; 
    string symbol = "STK";
    address randomUser = makeAddr("RandomUser");

    function setUp() public {
        stakingToken= new StakingToken(name, symbol);
    }

    function testStakingTokenMint(uint256 amount) public {
        vm.startPrank(randomUser);

        uint256 balanceBefore = IERC20(address(stakingToken)).balanceOf(randomUser);
        stakingToken.mint(amount);
        uint256 balanceAfter = IERC20(address(stakingToken)).balanceOf(randomUser); 
        assertEq(balanceAfter, balanceBefore + amount);
        vm.stopPrank(); 
    }

}