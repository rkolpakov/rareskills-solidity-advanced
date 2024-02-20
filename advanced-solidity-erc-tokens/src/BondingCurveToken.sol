// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BondingCurveToken is ERC20 {
    uint256 public constant INITIAL_PRICE = 1 ether;
    uint256 public constant PRICE_INCREMENT = 1 ether;

    event Deposit(address indexed sender, uint256 etherAmount, uint256 tokenAmount);
    event Withdraw(address indexed sender, uint256 tokenAmount, uint256 etherAmount);

    error NoEtherSent();
    error FailedToSendEth();
    error InsufficientTokenBalance(uint256 amount);
    error InvalidTokenAmount(uint256 amount);
    error NotEnoughEth(uint256 amount);
    error ContractInsufficientFunds();
    error MinAcceptableAmountNotMet(uint256 minAcceptableAmount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function deposit(uint256 minAcceptableTokenAmount) external payable {
        if (msg.value == 0) revert NoEtherSent();
        (uint256 tokenAmount, uint256 totalCost) = calculateTokenAmount(msg.value);
        if (tokenAmount == 0) revert NotEnoughEth(msg.value);
        if (tokenAmount < minAcceptableTokenAmount) revert MinAcceptableAmountNotMet(minAcceptableTokenAmount);

        _mint(msg.sender, tokenAmount);

        if (msg.value > totalCost) {
            (bool sent,) = payable(msg.sender).call{value: msg.value - totalCost}("");
            if (!sent) revert FailedToSendEth();
        }

        emit Deposit(msg.sender, msg.value, tokenAmount);
    }

    function withdraw(uint256 tokenAmount, uint256 minAcceptableEtherAmount) external {
        if (balanceOf(msg.sender) < tokenAmount) revert InsufficientTokenBalance(tokenAmount);
        if (tokenAmount == 0) revert InvalidTokenAmount(tokenAmount);

        uint256 etherToReturn = calculateEtherAmount(tokenAmount);

        if (etherToReturn < minAcceptableEtherAmount) revert MinAcceptableAmountNotMet(minAcceptableEtherAmount);

        _burn(msg.sender, tokenAmount);

        if (etherToReturn > address(this).balance) revert ContractInsufficientFunds();
        (bool sent,) = payable(msg.sender).call{value: etherToReturn}("");
        if (!sent) revert FailedToSendEth();

        emit Withdraw(msg.sender, tokenAmount, etherToReturn);
    }

    function calculateTokenAmount(uint256 etherAmount) public view returns (uint256 tokenAmount, uint256 totalCost) {
        uint256 currentPrice = _getCurrentPrice();

        while (totalCost + currentPrice <= etherAmount) {
            totalCost += currentPrice;
            currentPrice += PRICE_INCREMENT;
            tokenAmount++;
        }
    }

    function calculateEtherAmount(uint256 tokenAmount) public view returns (uint256 etherToReturn) {
        uint256 currentPrice = _getCurrentPrice() - PRICE_INCREMENT;

        for (uint256 i = 0; i < tokenAmount; i++) {
            etherToReturn += currentPrice;
            currentPrice -= PRICE_INCREMENT;
        }
    }

    function _getCurrentPrice() internal view returns (uint256) {
        return INITIAL_PRICE + (PRICE_INCREMENT * totalSupply());
    }
}
