// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mint} from "src/exchange/ERC20Mint.sol";
import {TrusterLenderPool} from "src/truster/TrusterLenderPool.sol";

contract TrusterEchidna {
    ERC20Mint public token;
    TrusterLenderPool public pool;
    address public immutable attacker;
    uint256 public constant INITIAL_POOL_BALANCE = 1_000_000e18;

    constructor() {
        token = new ERC20Mint("ChallengeToken", "CHL");
        pool = new TrusterLenderPool(token);

        token.mint(address(this), INITIAL_POOL_BALANCE);
        token.transfer(address(pool), INITIAL_POOL_BALANCE);

        attacker = address(this);
        token.mint(attacker, 1000e18);
    }

    function echidna_no_unauthorized_approvals() public view returns (bool) {
        // TODO: Implement the invariant
        return true;
    }

    function attemptApprovalExploit(uint256 amount) public {
        // TODO: Implement the fuzzer function
        return;
    }
}
