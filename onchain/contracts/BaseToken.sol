// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BaseToken is ERC20, Ownable{


    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 1000000);
    }
    
    function mint(uint _amount) public onlyOwner {
        _mint(msg.sender, _amount);
    }

} 