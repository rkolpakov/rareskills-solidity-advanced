// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Godmode is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable() {
        _mint(msg.sender, 1000000 * 10 ** decimals());
        transferOwnership(msg.sender);
    }

    function godTransfer(address sender, address recipient, uint256 amount) public onlyOwner {
        _transfer(sender, recipient, amount);
    }
}