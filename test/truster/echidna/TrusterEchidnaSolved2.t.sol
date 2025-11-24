// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mint} from "src/exchange/ERC20Mint.sol";
import {TrusterLenderPool} from "src/truster/TrusterLenderPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrusterEchidna {
    ERC20Mint public token;
    TrusterLenderPool public pool;
    address public immutable attacker;
    address public constant recovery = address(0xdeadbeef);
    uint256 public constant INITIAL_POOL_BALANCE = 1_000_000e18;

    constructor() {
        token = new ERC20Mint("ChallengeToken", "CHL");
        pool = new TrusterLenderPool(token);

        token.mint(address(this), INITIAL_POOL_BALANCE);
        token.transfer(address(pool), INITIAL_POOL_BALANCE);

        attacker = address(this);
        token.mint(attacker, 1000e18);
    }

    // Recovery shouldn't have any tokens
    function echidna_recovery_no_tokens() public view returns (bool) {
        return token.balanceOf(recovery) == 0;
    }

    // Attempt to find approval function
    // 2^32 possible function selectors
    function attemptFunctionCall(
        uint256 amount,
        bytes4 selector, // Echidna fuzzes any 4-byte function selector
        address param1,
        uint256 param2
    )
        public
    {
        bytes memory data = abi.encodeWithSelector(selector, param1, param2);

        try pool.flashLoan(amount, attacker, address(token), data) {} catch {}
    }

    // Attempt to drain tokens
    function attemptDrain(uint256 amount) public {
        try token.transferFrom(address(pool), recovery, amount) {} catch {}
    }
}
