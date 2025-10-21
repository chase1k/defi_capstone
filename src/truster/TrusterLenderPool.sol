// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity ^0.8.20;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {MyToken} from "../Token.sol";

/**
 * @title TrusterLenderPoolChallenge
 * @dev A challenge contract designed specifically for Echidna fuzzing
 * 
 * This contract contains multiple vulnerabilities that can be discovered
 * through systematic fuzzing with Echidna.
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    MyToken public immutable token;
    
    // Challenge state tracking
    uint256 public totalFlashLoans;
    uint256 public totalRepayments;
    mapping(address => uint256) public borrowerDebts;
    
    // Events for tracking
    event FlashLoanIssued(address indexed borrower, uint256 amount);
    event FlashLoanRepaid(address indexed borrower, uint256 amount);
    event UnauthorizedCall(address indexed target, bytes data);

    error RepayFailed();

    constructor(MyToken _token) {
        token = _token;
    }

    /**
     * @dev Main vulnerability: Arbitrary external call without proper validation
     * This allows attackers to manipulate the token contract or other contracts
     */
    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));
        
        // Transfer tokens to borrower
        if (amount > 0) {
            token.transfer(borrower, amount);
            totalFlashLoans++;
            borrowerDebts[borrower] += amount;
            emit FlashLoanIssued(borrower, amount);
        }
        
        // VULNERABILITY: Arbitrary external call
        // This allows attackers to call any function on any contract
        if (target != address(0) && data.length > 0) {
            target.functionCall(data);
            emit UnauthorizedCall(target, data);
        }

        // Check repayment
        if (token.balanceOf(address(this)) < balanceBefore) {
            revert RepayFailed();
        }

        totalRepayments++;
        emit FlashLoanRepaid(borrower, amount);
        return true;
    }

    /**
     * @dev Additional vulnerability: Missing access control
     * Anyone can call this function to manipulate pool state
     */
    function emergencyWithdraw(address to, uint256 amount) external {
        // VULNERABILITY: No access control
        token.transfer(to, amount);
    }

    /**
     * @dev Helper function for Echidna to check pool state
     */
    function getPoolState() external view returns (
        uint256 balance,
        uint256 loans,
        uint256 repayments
    ) {
        return (
            token.balanceOf(address(this)),
            totalFlashLoans,
            totalRepayments
        );
    }
}
