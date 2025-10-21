// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {MyToken} from "../Token.sol";

contract VulnerablePool {
    MyToken public immutable token;

    // internal accounting of how many tokens the pool *thinks* it has
    uint256 public accountingBalance;

    constructor(address _token) {
        token = MyToken(_token);
    }

    // deposit increases accountingBalance using transferFrom
    function deposit(uint256 amount) external {
        require(amount > 0, "zero");
        // user must have approved this contract
        bool ok = token.transferFrom(msg.sender, address(this), amount);
        require(ok, "transfer failed");
        accountingBalance += amount;
    }

    // a very small flash loan interface for demonstration/testing
    function flashLoan(uint256 amount, address receiver, bytes calldata data) external {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(amount <= balanceBefore, "not enough liquidity");

        // transfer tokens to receiver
        require(token.transfer(receiver, amount), "loan transfer failed");

        // allow arbitrary callback on receiver
        (bool success, ) = receiver.call(data);
        require(success, "callback failed");

        // require accounting neutrality — this is the invariant which can be violated
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter == accountingBalance, "invariant violated");
    }

    // withdraw by owner of funds in accounting (not needed for fuzz, but realistic)
    function withdraw(uint256 amount) external {
        require(amount <= accountingBalance, "insufficient accounting");
        accountingBalance -= amount;
        require(token.transfer(msg.sender, amount), "withdraw failed");
    }
}

