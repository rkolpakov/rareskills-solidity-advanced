// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Blacklisted} from "../src/ERC20Blacklisted.sol";

contract ERC20BlacklistedTest is Test {
    ERC20Blacklisted public erc20;

    address internal regularAccount;
    address internal blacklistedAccount;

    function setUp() public {
        erc20 = new ERC20Blacklisted("ERC20Blacklisted", "ERC20B");

        regularAccount = makeAddr("regularAccount");
        blacklistedAccount = makeAddr("blacklistedAccount");
    }

    function testAddToBlacklist() public {
        vm.expectEmit(address(erc20));
        emit ERC20Blacklisted.AddressAddedToBlacklist(blacklistedAccount);

        erc20.addToBlacklist(blacklistedAccount);

        assert(erc20.isBlacklisted(blacklistedAccount));
    }

    function testAddToBlacklistAlreadyBlacklisted() public {
        erc20.addToBlacklist(blacklistedAccount);

        vm.expectRevert(abi.encodeWithSelector(ERC20Blacklisted.AddressAlreadyBlacklisted.selector, blacklistedAccount));
        erc20.addToBlacklist(blacklistedAccount);
    }

    function testAddToBlacklistNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(regularAccount);
        erc20.addToBlacklist(blacklistedAccount);
    }

    function testRemoveFromBlacklist() public {
        erc20.addToBlacklist(blacklistedAccount);

        vm.expectEmit(address(erc20));
        emit ERC20Blacklisted.AddressRemovedFromBlacklist(blacklistedAccount);

        erc20.removeFromBlacklist(blacklistedAccount);

        assert(!erc20.isBlacklisted(blacklistedAccount));
    }

    function testRemoveFromBlacklistNotBlacklisted() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20Blacklisted.AddressNotBlacklisted.selector, regularAccount));
        erc20.removeFromBlacklist(regularAccount);
    }

    function testRemoveFromBlacklistNotOwner() public {
        erc20.addToBlacklist(blacklistedAccount);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(regularAccount);
        erc20.removeFromBlacklist(blacklistedAccount);
    }

    function testTransferBlacklistedAccount() public {
        erc20.addToBlacklist(blacklistedAccount);

        vm.expectRevert(abi.encodeWithSelector(ERC20Blacklisted.SenderBlacklisted.selector, blacklistedAccount));
        vm.prank(blacklistedAccount);
        erc20.transfer(regularAccount, 100);
    }

    function testTransferFromBlacklistedAccountSender() public {
        erc20.addToBlacklist(blacklistedAccount);

        vm.expectRevert(abi.encodeWithSelector(ERC20Blacklisted.SenderBlacklisted.selector, blacklistedAccount));
        erc20.transferFrom(blacklistedAccount, regularAccount, 100);
    }

    function testTransferFromBlacklistedAccountRecipient() public {
        erc20.addToBlacklist(blacklistedAccount);

        vm.expectRevert(abi.encodeWithSelector(ERC20Blacklisted.RecipientBlacklisted.selector, blacklistedAccount));
        erc20.transferFrom(regularAccount, blacklistedAccount, 100);
    }
}
