// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/exchange/ERC20Mint.sol";
import "src/unstoppable/VulnerablePool.sol";

contract UnstoppableEchidna is IERC3156FlashBorrower {
    ERC20Mint public token;
    VulnerablePool public vault;

    uint256 constant TOKENS_IN_VAULT = 1000000e18;
    uint256 constant INITIAL_ATTACKER_BALANCE = 10e18;

    constructor() {
        token = new ERC20Mint("Test Token", "TEST");
        vault = new VulnerablePool(token, "Vault token", "vTEST", msg.sender);

        token.mint(address(this), TOKENS_IN_VAULT);
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, address(this));
        token.mint(address(0x10000), INITIAL_ATTACKER_BALANCE);
    }

    function onFlashLoan(address initiator, address _token, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        require(
            initiator == address(this) && msg.sender == address(vault) && _token == address(vault.asset()) && fee == 0
        );

        IERC20(_token).approve(address(vault), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function echidna_test_flashloan() public view returns (bool) {}

    /**
     * CODE YOUR SOLUTION HERE
     */
    function action_deposit(uint256 amount) public {}

    /**
     * CODE YOUR SOLUTION HERE
     */
    function action_withdraw(uint256 shares) public {}

    /**
     * CODE YOUR SOLUTION HERE
     */
    function action_donate(uint256 amount) public {}

    /**
     * CODE YOUR SOLUTION HERE
     */
    function action_transfer(address to, uint256 amount) public {}
}

