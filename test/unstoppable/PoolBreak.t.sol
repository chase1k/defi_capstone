// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {MyToken} from "../../src/Token.sol";
import {VulnerablePool} from "../../src/unstoppable/VulnerablePool.sol";

contract PoolBreakTest is Test {
    MyToken token;
    VulnerablePool pool;
    address deployer = address(0xDeaD);
    address attacker = address(0xBEEF);

    function setUp() public {
        vm.prank(deployer);
        token = new MyToken("FuzzToken", "FZ");

        vm.prank(deployer);
        pool = new VulnerablePool(address(token));

        // mint balances
        vm.prank(deployer);
        token.mint(deployer, 1_000_000 ether);

        vm.prank(attacker);
        token.mint(attacker, 1000 ether);

        // deposit from deployer
        vm.prank(deployer);
        token.approve(address(pool), type(uint256).max);

        vm.prank(deployer);
        pool.deposit(1000 ether);
    }

    function testDirectTransferBreaksFlashLoan() public {
        // attacker sends tokens directly to pool
        vm.prank(attacker);
        token.transfer(address(pool), 100 ether);

        // ensure balances differ
        uint256 bal = token.balanceOf(address(pool));
        uint256 accounting = pool.accountingBalance();
        assertTrue(bal != accounting, "expected mismatch");

        // expect revert with message "invariant violated"
        vm.expectRevert(bytes("invariant violated"));
        pool.flashLoan(1, address(this), "");
    }
}

