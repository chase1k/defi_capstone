// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../lib/solmate/src/tokens/ERC20.sol";

contract MyToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, 18) {}

    // simple mint for tests/fuzzing (anyone can mint in this test token)
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // expose a convenience function wrapping transferFrom for easier calls in fuzz harness
    function safeTransferFrom(address from, address to, uint256 amount) external returns (bool) {
        return transferFrom(from, to, amount);
    }
}

