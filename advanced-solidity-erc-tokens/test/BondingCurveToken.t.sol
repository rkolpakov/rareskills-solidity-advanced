// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BondingCurveToken} from "../src/BondingCurveToken.sol";

contract BondingCurveTokenTest is Test {
    BondingCurveToken public erc20;

    function setUp() public {
        erc20 = new BondingCurveToken("BondingCurveToken", "BCT");
    }

    function testDeposit() public {
        (uint256 tokenAmount,) = erc20.calculateTokenAmount(1 ether);
        assertEq(tokenAmount, 1);

        uint256 balanceBefore = address(this).balance;
        vm.expectEmit(address(erc20));
        emit BondingCurveToken.Deposit(address(this), 1 ether, 1);
        erc20.deposit{value: 1 ether}(1);
        assertEq(erc20.balanceOf(address(this)), 1);
        assertEq(address(this).balance, balanceBefore - 1 ether);

        (tokenAmount,) = erc20.calculateTokenAmount(2 ether);
        assertEq(tokenAmount, 1);

        balanceBefore = address(this).balance;
        erc20.deposit{value: 2 ether}(1);
        assertEq(erc20.balanceOf(address(this)), 2);
        assertEq(address(this).balance, balanceBefore - 2 ether);

        (tokenAmount,) = erc20.calculateTokenAmount(3 ether);
        assertEq(tokenAmount, 1);

        balanceBefore = address(this).balance;
        erc20.deposit{value: 4 ether}(1);
        assertEq(erc20.balanceOf(address(this)), 3);
        assertEq(address(this).balance, balanceBefore - 3 ether);
    }

    function testDepositLessThanAcceptableAmount() public {
        vm.expectRevert(abi.encodeWithSelector(BondingCurveToken.MinAcceptableAmountNotMet.selector, 2));
        erc20.deposit{value: 1 ether}(2);
    }

    function testDepositNoEtherSent() public {
        vm.expectRevert(abi.encodeWithSelector(BondingCurveToken.NoEtherSent.selector));
        erc20.deposit{value: 0}(1);
    }

    function testDepositNotEnoughEth() public {
        vm.expectRevert(abi.encodeWithSelector(BondingCurveToken.NotEnoughEth.selector, 1 ether - 1));
        erc20.deposit{value: 1 ether - 1}(1);
    }

    function testWithdraw() public {
        erc20.deposit{value: 10 ether}(4);
        assertEq(erc20.balanceOf(address(this)), 4);

        uint256 balanceBefore = address(this).balance;
        vm.expectEmit(address(erc20));
        emit BondingCurveToken.Withdraw(address(this), 1, 4 ether);
        erc20.withdraw(1, 4 ether);
        assertEq(erc20.balanceOf(address(this)), 3);
        assertEq(address(this).balance, balanceBefore + 4 ether);

        balanceBefore = address(this).balance;
        erc20.withdraw(3, 6 ether);
        assertEq(erc20.balanceOf(address(this)), 0);
        assertEq(address(this).balance, balanceBefore + 6 ether);
    }

    function testWithdrawInsufficientTokenBalance() public {
        erc20.deposit{value: 10 ether}(4);
        vm.expectRevert(abi.encodeWithSelector(BondingCurveToken.InsufficientTokenBalance.selector, 5));
        erc20.withdraw(5, 4 ether);
    }

    function testWithdrawInvalidTokenAmount() public {
        erc20.deposit{value: 10 ether}(4);
        vm.expectRevert(abi.encodeWithSelector(BondingCurveToken.InvalidTokenAmount.selector, 0));
        erc20.withdraw(0, 4 ether);
    }

    function testWithdrawMinAcceptableAmountNotMet() public {
        erc20.deposit{value: 10 ether}(4);
        vm.expectRevert(abi.encodeWithSelector(BondingCurveToken.MinAcceptableAmountNotMet.selector, 5 ether));
        erc20.withdraw(1, 5 ether);
    }

    receive() external payable {}
}
