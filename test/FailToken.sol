// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract FailToken {
        function transferFrom(address, address, uint256) external pure returns (bool) {
            return false; 
        }
        function transfer(address, uint256) external pure returns (bool) {
            return false;
        }
    }