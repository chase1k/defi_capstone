pragma solidity ^0.8.0;

import "src/naive-receiver/NaiveReceiver.sol";
import "src/exchange/ERC20Mint.sol";

contract EchidnaNaiveReceiver {
    NaiveReceiverLenderPool public pool;
    FlashLoanReceiver public receiver;
    ERC20Mint public token;

    uint256 public constant INITIAL_RECEIVER_BALANCE = 10 ether;
    uint256 public constant INITIAL_POOL_BALANCE = 1000 ether;
    uint256 public constant FEE = 1 ether;

    constructor() {
        token = new ERC20Mint("TESTTOKEN", "TTOK");
        pool = new NaiveReceiverLenderPool(address(token));
        receiver = new FlashLoanReceiver(address(pool));

        token.mint(address(pool), INITIAL_POOL_BALANCE);
        token.mint(address(receiver), INITIAL_RECEIVER_BALANCE);
    }

    function test_normalFlashLoan(uint256 amount) public {
        amount = 1 ether + (amount % 100 ether);

        try pool.flashLoan(address(receiver), amount) {} catch {}
    }

    function test_zeroAmountLoan() public {
        try pool.flashLoan(address(receiver), 0) {} catch {}
    }

    function test_maxAmountLoan() public {
        uint256 maxAmount = token.balanceOf(address(pool));

        try pool.flashLoan(address(receiver), maxAmount) {} catch {}
    }

    function test_sequentialLoans(uint256 amount1, uint256 amount2) public {
        amount1 = amount1 % 50 ether;
        amount2 = amount2 % 50 ether;

        try pool.flashLoan(address(receiver), amount1) {} catch {}
        try pool.flashLoan(address(receiver), amount2) {} catch {}
    }

    function test_repeatedUnauthorizedCalls(uint8 times) public {
        times = times % 15 + 1;

        for (uint256 i = 0; i < times; i++) {
            try pool.flashLoan(address(receiver), 0) {}
            catch {
                break;
            }
        }
    }

    function test_drainWithVariousAmounts(uint256 amount) public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 0;
        amounts[1] = 1 ether;
        amounts[2] = amount % 100 ether;
        amounts[3] = INITIAL_POOL_BALANCE;

        uint256 idx = amount % 4;

        try pool.flashLoan(address(receiver), amounts[idx]) {} catch {}
    }

    function echidna_receiver_not_drained() public view returns (bool) {
        uint256 currentBalance = token.balanceOf(address(receiver));

        uint256 maxLegitLoss = FEE * 2;

        return currentBalance >= INITIAL_RECEIVER_BALANCE - maxLegitLoss;
    }

    function echidna_pool_gains_fees() public view returns (bool) {
        uint256 currentBalance = token.balanceOf(address(pool));
        return currentBalance >= INITIAL_POOL_BALANCE;
    }

    function echidna_token_conservation() public view returns (bool) {
        uint256 totalNow = token.balanceOf(address(receiver)) + token.balanceOf(address(pool));
        uint256 totalInitial = INITIAL_RECEIVER_BALANCE + INITIAL_POOL_BALANCE;

        return totalNow == totalInitial;
    }

    function echidna_receiver_has_balance() public view returns (bool) {
        return token.balanceOf(address(receiver)) > 0;
    }

    function echidna_reasonable_fees() public view returns (bool) {
        uint256 poolGain = token.balanceOf(address(pool)) - INITIAL_POOL_BALANCE;

        return poolGain <= FEE * 10;
    }

    function debug_receiverBalance() public view returns (uint256) {
        return token.balanceOf(address(receiver));
    }

    function debug_poolBalance() public view returns (uint256) {
        return token.balanceOf(address(pool));
    }

    function debug_receiverLoss() public view returns (uint256) {
        uint256 current = token.balanceOf(address(receiver));
        if (current >= INITIAL_RECEIVER_BALANCE) return 0;
        return INITIAL_RECEIVER_BALANCE - current;
    }

    function debug_poolGain() public view returns (uint256) {
        uint256 current = token.balanceOf(address(pool));
        if (current <= INITIAL_POOL_BALANCE) return 0;
        return current - INITIAL_POOL_BALANCE;
    }
}

