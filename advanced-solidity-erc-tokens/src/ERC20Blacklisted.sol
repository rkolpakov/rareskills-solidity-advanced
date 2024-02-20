// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Blacklisted is ERC20, Ownable {
    mapping(address account => bool) public _blacklist;

    event AddressAddedToBlacklist(address account);
    event AddressRemovedFromBlacklist(address account);

    error AddressAlreadyBlacklisted(address account);
    error AddressNotBlacklisted(address account);
    error RecipientBlacklisted(address account);
    error SenderBlacklisted(address account);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable() {
        _mint(msg.sender, 1000000 * 10 ** decimals());
        transferOwnership(msg.sender);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_blacklist[msg.sender]) {
            revert SenderBlacklisted(msg.sender);
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (_blacklist[sender]) {
            revert SenderBlacklisted(sender);
        }
        if (_blacklist[recipient]) {
            revert RecipientBlacklisted(recipient);
        }
        return super.transferFrom(sender, recipient, amount);
    }

    function addToBlacklist(address account) public onlyOwner {
        if (_blacklist[account]) {
            revert AddressAlreadyBlacklisted(account);
        }
        _blacklist[account] = true;
        emit AddressAddedToBlacklist(account);
    }

    function removeFromBlacklist(address account) public onlyOwner {
        if (!_blacklist[account]) {
            revert AddressNotBlacklisted(account);
        }
        _blacklist[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }
}
