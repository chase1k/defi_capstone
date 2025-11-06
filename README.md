# VulnNet

A collection of vulnerable smart contracts and their corresponding test suites for security research and educational purposes.

## Running Tests

### Forge Tests

Run Forge tests for the Unstoppable challenge:

```bash
forge test --match-path test/unstoppable/Unstoppable.t.sol
```

### Echidna Tests

Run Echidna property-based fuzzing tests for Truster challenges:

```bash
# Run the unsolved challenge template
echidna test/truster/echidna/TrusterEchidna.t.sol --contract TrusterEchidna

# Run the solved version
echidna test/truster/echidna/SolvedTrusterEchidna.t.sol --contract TrusterEchidna
```

## Overview

VulnNet contains vulnerable smart contracts organized by vulnerability type, along with comprehensive test suites.

### Source Files (`src/`)

- **`exchange/`**: Exchange-related contracts including ERC20Mint token, Factory, Router, and Pair contracts for a Uniswap-like DEX implementation
- **`truster/`**: TrusterLenderPool - A flash loan pool vulnerable to unauthorized token approvals via malicious callback data
- **`unstoppable/`**: VulnerablePool - An ERC4626 vault with a flash loan vulnerability where direct token transfers break the accounting invariant

### Test Files (`test/`)

- **`truster/`**: Tests and Echidna fuzzing harnesses for the Truster vulnerability
- **`unstoppable/`**: Forge tests and Echidna fuzzing harnesses for the Unstoppable vulnerability
- **`ExchangeTest.t.sol`**: Tests for the exchange contracts

Each vulnerability includes both solved and unsolved test templates for educational purposes.
