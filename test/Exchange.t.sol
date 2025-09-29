// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "../src/EscrowSwap.sol";
import "../src/SimpleToken.sol";

contract ExchangeTest is Test {
    address alice;
    address bob;

    SimpleToken tokenA;
    SimpleToken tokenB;

    function setUp() public {
        // Deterministic, labeled addresses
        alice = makeAddr("ALICE");
        bob = makeAddr("BOB");

        // Give Alice some ETH for gas and transfers
        vm.deal(alice, 10 ether);

        // Deploy two mock tokens and mint to both parties
        tokenA = new SimpleToken("TokenA", "TKA");
        tokenB = new SimpleToken("TokenB", "TKB");

        tokenA.mint(alice, 1_000 ether);
        tokenB.mint(bob, 1_000 ether);
    }

    function testEthTransfer3Ether() public {
        // Alice sends 3 ETH to Bob
        vm.prank(alice);
        (bool ok, ) = bob.call{value: 3 ether}("");
        assertTrue(ok, "eth xfer failed");
        assertEq(bob.balance, 3 ether, "bob eth");
        assertEq(alice.balance, 7 ether, "alice eth");
    }

    function testTokenEscrowSwap() public {
        uint256 amountA = 250 ether; // Alice gives 250 TKA
        uint256 amountB = 100 ether; // Bob gives 100 TKB

        EscrowSwap swap = new EscrowSwap(
            IERC20(address(tokenA)),
            IERC20(address(tokenB)),
            alice,
            bob,
            amountA,
            amountB
        );

        // Approvals
        vm.prank(alice);
        tokenA.approve(address(swap), amountA);
        vm.prank(bob);
        tokenB.approve(address(swap), amountB);

        // Deposits (order doesn't matter)
        vm.prank(alice);
        swap.depositA();
        vm.prank(bob);
        swap.depositB();

        // Anyone can settle once both are in
        swap.settle();

        // Post-conditions
        assertEq(tokenA.balanceOf(bob), amountA, "bob got A");
        assertEq(tokenB.balanceOf(alice), amountB, "alice got B");
        assertEq(tokenA.balanceOf(address(swap)), 0, "escrow A empty");
        assertEq(tokenB.balanceOf(address(swap)), 0, "escrow B empty");
    }
}
