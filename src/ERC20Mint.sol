// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Mint is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_) 
        Ownable(msg.sender)
    {}

    /// @notice allow the owner or anyone (for testing) to mint
    function mint(address to, uint256 amount) external {
        // remove the require to allow anyone to mint on testnet/dev
        _mint(to, amount);
    }
}

