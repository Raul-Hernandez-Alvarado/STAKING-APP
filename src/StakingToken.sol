// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0; 

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20 { 
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

    }

    function mint (uint256 _amount) external { // Lógica para mintear tokens de recompensa
        _mint(msg.sender, _amount);
    }
}