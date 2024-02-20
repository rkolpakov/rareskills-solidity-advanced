// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UntrustedEscrow is IERC777Recipient {
    using SafeERC20 for IERC20;

    uint256 public constant TIMELOCK = 3 days;

    struct Obligation {
        address token;
        address recipient;
        address depositor;
        uint256 amount;
        uint256 depositedAt;
        bool received;
    }

    mapping(bytes32 => Obligation) public _obligations;

    event Deposited(bytes32 indexed id, address depositor, address recipient, address token, uint256 amount);
    event Withdrawn(bytes32 indexed id, address depositor, address recipient, address token, uint256 amount);

    error TokenIsZeroAddress();
    error InvalidAmount(uint256 amount);
    error RecipientIsZeroAddress();
    error InvalidIds(bytes32[] ids);
    error ObligationNotFound(bytes32 id);
    error ObligationNotUnlocked(bytes32 id, uint256 unlockAt, uint256 currentTimestamp);
    error ObligationAlreadyReceived(bytes32 id);
    error TransfersNotAllowed();

    function deposit(address token, uint256 amount, address recipient) external {
        if (amount == 0) revert InvalidAmount(amount);
        if (token == address(0)) revert TokenIsZeroAddress();
        if (recipient == address(0)) revert RecipientIsZeroAddress();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        bytes32 id = keccak256(abi.encodePacked(token, amount, msg.sender, recipient, block.timestamp));

        _obligations[id] = Obligation({
            token: token,
            recipient: recipient,
            depositor: msg.sender,
            amount: amount,
            depositedAt: block.timestamp,
            received: false
        });

        emit Deposited(id, msg.sender, recipient, token, amount);
    }

    function withdraw(bytes32[] calldata ids) external {
        if (ids.length == 0) revert InvalidIds(ids);

        for (uint256 i = 0; i < ids.length; i++) {
            Obligation storage obligation = _obligations[ids[i]];

            if (_obligations[ids[i]].token == address(0)) {
                revert ObligationNotFound(ids[i]);
            }
            if (block.timestamp < obligation.depositedAt + TIMELOCK) {
                revert ObligationNotUnlocked(ids[i], obligation.depositedAt + TIMELOCK, block.timestamp);
            }
            if (obligation.received) revert ObligationAlreadyReceived(ids[i]);

            obligation.received = true;

            IERC20(obligation.token).safeTransfer(obligation.recipient, obligation.amount);

            emit Withdrawn(ids[i], obligation.depositor, obligation.recipient, obligation.token, obligation.amount);
        }
    }

    function tokensReceived(address, address, address, uint256, bytes calldata, bytes calldata)
        external
        pure
        override
    {
        revert TransfersNotAllowed();
    }
}
