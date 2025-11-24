# Hacking the Chain 
## DVDeFi Smart Contract Analysis

An evaluation of [DVDeFi](https://github.com/theredguild/damn-vulnerable-defi) smart contracts for [Echidna usage](https://github.com/crytic/echidna). Expanding upon [damn-vulnerable-defi-echidna](https://github.com/crytic/damn-vulnerable-defi-echidna), for educational purposes only.

## Running Tests

### Forge Tests

Unstoppable
```bash
forge test --match-path test/unstoppable/Unstoppable.t.sol
```

PuppetV2
```bash
forge test --mp test/puppet-v2/PuppetV2.t.sol -vv
```

PuppetV3 (Mainnet Forking)
```bash
source .env && forge test --mt "test_puppetV3" --fork-url $MAINNET_FORKING_URL
```

### Echidna Tests

Truster
```bash
# Run the unsolved challenge template
echidna test/truster/echidna/TrusterEchidna.t.sol --contract TrusterEchidna

# Run the solved version
echidna test/truster/echidna/TrusterEchidnaSolved.t.sol --contract TrusterEchidna
```

PuppetV3 (Mainnet Forking)
```bash
./scripts/puppetv3echidna.t.sh
```

## Overview

This VulnNet contains vulnerable smart contracts organized by vulnerability type, along with their respective tests.

### Infrastructure Files

| Component | Description | Files |
|-----------|-------------|-------|
| **Uniswap V2 Contracts** | Pre-compiled Uniswap V2 contracts for PuppetV2 tests | `builds/uniswap/UniswapV2Factory.json`, `builds/uniswap/UniswapV2Router02.json` |
| **Exchange Contracts** | Uniswap-like DEX implementation | `src/exchange/ERC20Mint.sol`, `src/exchange/Factory.sol`, `src/exchange/Router.sol`, `src/exchange/Pair.sol`, `src/exchange/interfaces/IUniswapV2Factory.sol`, `src/exchange/interfaces/IUniswapV2Pair.sol`, `src/exchange/interfaces/IUniswapV2Router.sol` |
| **Exchange Tests** | Tests for exchange contracts | `test/ExchangeTest.t.sol` |

### Challenges (DVDeFi V4 Implementations)

| Challenge | Vulnerability | Source | Tests |
|-----------|---------------|--------|-------|
| **Unstoppable** | ERC4626 vault vulnerable to direct token transfers breaking accounting | `src/unstoppable/VulnerablePool.sol` | [x] Forge [x] Echidna |
| **Naive Receiver** | Flash loan receiver vulnerable to repeated drain attacks | `src/naive-receiver/NaiveReceiver.sol` | [x] Forge [ ] Echidna |
| **Truster** | Flash loan pool vulnerable to arbitrary function calls via malicious callback data | `src/truster/TrusterLenderPool.sol` | [x] Forge [x] Echidna |
| **Puppet V2** | Low liquidity pool vulnerable to price oracle manipulation via Uniswap V2 | `src/puppet-v2/PuppetV2Pool.sol`, `src/puppet-v2/UniswapV2Library.sol` | [x] Forge [ ] Echidna |
| **Puppet V3** | Low liquidity pool vulnerable to price oracle manipulation via Uniswap V3 | `src/puppet-v3/PuppetV3Pool.sol`, `src/puppet-v3/OracleHelper.sol`, `src/puppet-v3/INonfungiblePositionManager.sol` | [x] Forge [x] Echidna | 

