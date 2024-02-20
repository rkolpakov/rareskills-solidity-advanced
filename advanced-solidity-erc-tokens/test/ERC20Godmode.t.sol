// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Godmode} from "../src/ERC20Godmode.sol";

contract ERC20BlacklistedTest is Test {
    ERC20Godmode public erc20;

    address sender = makeAddr("sender");
    address recipient = makeAddr("recipient");
    address stranger = makeAddr("stranger");

    function setUp() public {
        erc20 = new ERC20Godmode("ERC20Godmode", "ERC20G");
    }

    function testGodTransfer() public {
        erc20.transfer(sender, 100);
        assertEq(erc20.balanceOf(sender), 100);

        erc20.godTransfer(sender, recipient, 100);
        assertEq(erc20.balanceOf(sender), 0);
        assertEq(erc20.balanceOf(recipient), 100);
    }

    function testGodTransferFromStranger() public {
        erc20.transfer(sender, 100);
        assertEq(erc20.balanceOf(sender), 100);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(stranger);

        erc20.godTransfer(sender, recipient, 100);
    }
}