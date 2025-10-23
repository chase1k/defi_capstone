# Echidna Fuzzing Challenge: Truster Lender Pool

## Overview

This challenge demonstrates how **Echidna** fuzzing can systematically discover vulnerabilities in smart contracts. The Truster Lender Pool contains multiple exploitable vulnerabilities that Echidna can find through property-based testing.

## The Vulnerability

The `TrusterLenderPool.flashLoan()` function contains a critical vulnerability:

```solidity
target.functionCall(data);
```

This allows attackers to:
1. Call `flashLoan` with `amount=0` (no tokens borrowed)
2. Pass the token contract address as `target`
3. Encode `approve(attacker, poolBalance)` as `data`
4. The pool approves the attacker to spend its tokens
5. Attacker calls `transferFrom` to drain the pool

## Installation

```bash
# Install Echidna using Docker (recommended)
docker pull trailofbits/eth-security-toolbox

# Or install from source
git clone https://github.com/crytic/echidna.git
cd echidna
cargo build --release
```

## Running the Challenge

```bash
# Run the Echidna challenge
echidna test/truster/TrusterEchidnaChallenge.sol --contract TrusterEchidnaChallenge --config echidna.yaml

# Run with corpus generation
echidna test/truster/TrusterEchidnaChallenge.sol --contract TrusterEchidnaChallenge --config echidna.yaml --corpus-dir echidna_corpus

# Run with verbose output
echidna test/truster/TrusterEchidnaChallenge.sol --contract TrusterEchidnaChallenge --config echidna.yaml -v
```

## Expected Results

Echidna should discover violations of these invariants:

1. **`echidna_pool_balance_invariant()`** - Pool balance should never decrease significantly
2. **`echidna_no_unauthorized_approvals()`** - Pool should never approve unknown addresses
3. **`echidna_attacker_balance_limited()`** - Attacker should not accumulate excessive tokens
4. **`echidna_flash_loan_accounting()`** - Flash loan accounting should be consistent

**Sample Output:**
```
echidna_no_unauthorized_approvals: failed!💥
  Call sequence:
    attemptApprovalExploit(1000000000000000000000000)
```

## Challenge Features

- **Multiple Attack Vectors**: Approval exploit, emergency withdraw, generic calls
- **Comprehensive Invariants**: Four different properties to test
- **State Tracking**: Detailed monitoring of exploit attempts and successes
- **Educational Value**: Demonstrates systematic vulnerability discovery

## Key Files

- `src/truster/TrusterLenderPool.sol` - Enhanced vulnerable pool contract
- `test/truster/TrusterEchidnaChallenge.sol` - Comprehensive Echidna test
- `echidna.yaml` - Echidna configuration
- `test/truster/Truster.t.sol` - Basic exploit demonstration

## Advanced Usage

### Custom Configuration

Modify `echidna.yaml` to adjust:
- `testLimit`: Number of test cases to generate
- `seqLen`: Length of transaction sequences
- `timeout`: Maximum time per test
- `filterFunctions`: Which functions to test

### Corpus Analysis

Echidna saves interesting test cases to `echidna_corpus/`:
```bash
# Analyze corpus results
ls echidna_corpus/
cat echidna_corpus/coverage/*.txt
```

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure all dependencies are installed
2. **Compilation Errors**: Check Solidity version compatibility (0.8.20)
3. **Timeout Issues**: Increase timeout in `echidna.yaml`
4. **Memory Issues**: Reduce `testLimit` or `seqLen`

### Debugging

Enable verbose output:
```bash
echidna test/truster/TrusterEchidnaChallenge.sol --contract TrusterEchidnaChallenge --config echidna.yaml -v
```

## Conclusion

This challenge demonstrates how Echidna excels at finding property violations and edge cases through systematic exploration, making it an excellent tool for smart contract security auditing.