// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Godmode} from "../src/ERC20Godmode.sol";
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";

contract UntrustedEscrowTest is Test {
    ERC20Godmode public token;
    UntrustedEscrow public escrow;

    address public depositor = makeAddr("depositor");
    address public recipient = makeAddr("recipient");
    address public stranger = makeAddr("stranger");

    function setUp() public {
        token = new ERC20Godmode("ERC20Token", "ERC20");
        escrow = new UntrustedEscrow();

        address[] memory operators = new address[](1);
        operators[0] = address(depositor);

        token.transfer(depositor, 100 ether);
    }

    function testDeposit() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 1 ether);

        vm.expectEmit(address(escrow));
        bytes32 expectedId =
            keccak256(abi.encodePacked(address(token), uint256(1 ether), depositor, recipient, block.timestamp));
        emit UntrustedEscrow.Deposited(expectedId, depositor, recipient, address(token), 1 ether);
        escrow.deposit(address(token), 1 ether, recipient);

        assertEq(token.balanceOf(address(escrow)), 1 ether);
        assertEq(token.balanceOf(depositor), 99 ether);

        UntrustedEscrow.Obligation memory obligation;
        (
            obligation.token,
            obligation.recipient,
            obligation.depositor,
            obligation.amount,
            obligation.depositedAt,
            obligation.received
        ) = escrow._obligations(expectedId);

        assertEq(obligation.amount, 1 ether);
        assertEq(obligation.depositor, depositor);
        assertEq(obligation.recipient, recipient);
        assertEq(obligation.token, address(token));
        assertEq(obligation.depositedAt, block.timestamp);
        assertEq(obligation.received, false);
    }

    function testDepositZeroAmount() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 0);
        vm.expectRevert(abi.encodePacked(UntrustedEscrow.InvalidAmount.selector, uint256(0)));
        escrow.deposit(address(token), 0, recipient);
    }

    function testDepositZeroRecipient() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 1 ether);
        vm.expectRevert(UntrustedEscrow.RecipientIsZeroAddress.selector);
        escrow.deposit(address(token), 1 ether, address(0));
    }

    function testDepositZeroToken() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 1 ether);
        vm.expectRevert(abi.encodePacked(UntrustedEscrow.TokenIsZeroAddress.selector));
        escrow.deposit(address(0), 1 ether, recipient);
    }

    function testWithdraw() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 1 ether);

        bytes32 expectedId =
            keccak256(abi.encodePacked(address(token), uint256(1 ether), depositor, recipient, block.timestamp));
        escrow.deposit(address(token), 1 ether, recipient);
        vm.stopPrank();

        skip(escrow.TIMELOCK());

        vm.startPrank(recipient);
        vm.expectEmit(address(escrow));
        emit UntrustedEscrow.Withdrawn(expectedId, depositor, recipient, address(token), 1 ether);

        bytes32[] memory payload = new bytes32[](1);
        payload[0] = expectedId;

        escrow.withdraw(payload);
    }

    function testWithdrawNotExistingObligation() public {
        bytes32[] memory payload = new bytes32[](1);
        payload[0] = keccak256(abi.encodePacked("not-existing-id"));

        vm.startPrank(recipient);
        vm.expectRevert(abi.encodePacked(UntrustedEscrow.ObligationNotFound.selector, payload[0]));
        escrow.withdraw(payload);
    }

    function testWithdrawAlreadyReceivedObligation() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 1 ether);
        bytes32 expectedId =
            keccak256(abi.encodePacked(address(token), uint256(1 ether), depositor, recipient, block.timestamp));
        escrow.deposit(address(token), 1 ether, recipient);
        vm.stopPrank();

        skip(escrow.TIMELOCK());

        bytes32[] memory payload = new bytes32[](1);
        payload[0] = expectedId;

        vm.startPrank(recipient);
        escrow.withdraw(payload);
        vm.expectRevert(abi.encodePacked(UntrustedEscrow.ObligationAlreadyReceived.selector, payload[0]));
        escrow.withdraw(payload);
    }

    function testWithdrawBeforeUnlocked() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 1 ether);
        bytes32 expectedId =
            keccak256(abi.encodePacked(address(token), uint256(1 ether), depositor, recipient, block.timestamp));
        escrow.deposit(address(token), 1 ether, recipient);
        vm.stopPrank();

        bytes32[] memory payload = new bytes32[](1);
        payload[0] = expectedId;

        vm.startPrank(recipient);
        vm.expectRevert(
            abi.encodePacked(
                UntrustedEscrow.ObligationNotUnlocked.selector,
                payload[0],
                block.timestamp + escrow.TIMELOCK(),
                block.timestamp
            )
        );
        escrow.withdraw(payload);
    }

    function testWithdrawFromStranger() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 1 ether);
        bytes32 expectedId =
            keccak256(abi.encodePacked(address(token), uint256(1 ether), depositor, recipient, block.timestamp));
        escrow.deposit(address(token), 1 ether, recipient);
        vm.stopPrank();

        skip(escrow.TIMELOCK());

        bytes32[] memory payload = new bytes32[](1);
        payload[0] = expectedId;

        vm.startPrank(stranger);
        escrow.withdraw(payload);
    }

    function testWithdrawMultipleObligations() public {
        vm.startPrank(depositor);
        token.approve(address(escrow), 3 ether);
        bytes32 expectedId1 =
            keccak256(abi.encodePacked(address(token), uint256(1 ether), depositor, recipient, block.timestamp));
        escrow.deposit(address(token), 1 ether, recipient);
        bytes32 expectedId2 =
            keccak256(abi.encodePacked(address(token), uint256(2 ether), depositor, recipient, block.timestamp));
        escrow.deposit(address(token), 2 ether, recipient);
        vm.stopPrank();

        bytes32[] memory payload = new bytes32[](2);
        payload[0] = expectedId1;
        payload[1] = expectedId2;

        skip(escrow.TIMELOCK());

        vm.startPrank(recipient);
        vm.expectEmit(address(escrow));
        emit UntrustedEscrow.Withdrawn(expectedId1, depositor, recipient, address(token), 1 ether);
        emit UntrustedEscrow.Withdrawn(expectedId2, depositor, recipient, address(token), 2 ether);

        escrow.withdraw(payload);
    }
}
