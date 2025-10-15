## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
## Overview of VulnNet

This branch consists of two parts the ./src files and ./test files

### ./src files
Token.sol
MyToken a solmate based ERC20 test token

VulnerablePool.sol
Remake of the Damn Vulnerable Defi Unstopable vulnerability
flash loan contract contains lines of code that are vulnerable if an attacker were to send tokens directly to the vulnerable pool. This is due to the check involved with BalanceAfter required to be equal to the accounting balance. 

### Vulnerability summary
The contract trusts an internal accounting balance which is compared to balance after. If an attacker were to send tokens directly to the vulnerable pool it could cause accounting balance to not be updated properly which will revert due to the check that requires balance after to accounting balance causing a denial of service for flashloans

### ./test files
Serve as unit tests to setup the vunerable pool along with another externally owned account that will attempt to call flashloan contract. The tests in these files are to determine if the flash loans work as they should and if the attack can be exploited. 
