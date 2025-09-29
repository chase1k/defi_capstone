// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title Simple two-party OTC escrow swap between Alice and Bob
/// @notice Alice deposits tokenA, Bob deposits tokenB. Once both are in, either can settle.
contract EscrowSwap {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    address public immutable alice;
    address public immutable bob;
    uint256 public immutable amountA; // Alice will deposit this amount of tokenA
    uint256 public immutable amountB; // Bob will deposit this amount of tokenB

    bool public depositedA;
    bool public depositedB;
    bool public settled;

    event DepositedA(address indexed from, uint256 amount);
    event DepositedB(address indexed from, uint256 amount);
    event Settled(address indexed alice, address indexed bob);

    error OnlyAlice();
    error OnlyBob();
    error AlreadyDeposited();
    error NotReady();
    error AlreadySettled();

    constructor(
        IERC20 _tokenA,
        IERC20 _tokenB,
        address _alice,
        address _bob,
        uint256 _amountA,
        uint256 _amountB
    ) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        alice = _alice;
        bob = _bob;
        amountA = _amountA;
        amountB = _amountB;
    }

    function depositA() external {
        if (msg.sender != alice) revert OnlyAlice();
        if (depositedA) revert AlreadyDeposited();
        depositedA = true;
        require(tokenA.transferFrom(alice, address(this), amountA), "xferA");
        emit DepositedA(alice, amountA);
    }

    function depositB() external {
        if (msg.sender != bob) revert OnlyBob();
        if (depositedB) revert AlreadyDeposited();
        depositedB = true;
        require(tokenB.transferFrom(bob, address(this), amountB), "xferB");
        emit DepositedB(bob, amountB);
    }

    function settle() external {
        if (settled) revert AlreadySettled();
        if (!(depositedA && depositedB)) revert NotReady();
        settled = true;
    }
}
