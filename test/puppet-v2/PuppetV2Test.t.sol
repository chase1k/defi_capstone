// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/exchange/ERC20Mint.sol";

import "@uniswap/v2-core/contracts/UniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import "../src/PuppetV2Pool.sol";

contract PuppetV2Test is Test {
    ERC20Mint token;
    IWETH weth;
    UniswapV2Factory factory;
    UniswapV2Router02 router;
    address pair;
    PuppetV2Pool pool;

    address attacker = address(0xA11CE);

    function setUp() public {
        // -----------------------
        // 1. Deploy ERC20Mint
        // -----------------------
        token = new ERC20Mint("MyToken", "MTK");

        // -----------------------
        // 2. Deploy WETH9
        // -----------------------
        WETH9 _weth = new WETH9();
        weth = IWETH(address(_weth));

        // -----------------------
        // 3. Deploy Uniswap V2 factory + router
        // -----------------------
        factory = new UniswapV2Factory(address(this));
        router = new UniswapV2Router02(address(factory), address(weth));

        // -----------------------
        // 4. Add liquidity (token–WETH)
        // -----------------------

        // mint tokens for liquidity provider (this contract)
        token.mint(address(this), 10000 ether);
        token.approve(address(router), type(uint256).max);

        // wrap ETH → WETH
        _weth.deposit{value: 100 ether}();
        _weth.approve(address(router), type(uint256).max);

        router.addLiquidityETH{value: 50 ether}(
            address(token),
            5000 ether,
            0,
            0,
            address(this),
            block.timestamp
        );

        // Fetch the pair address from Uniswap factory
        pair = factory.getPair(address(token), address(weth));
        require(pair != address(0), "PAIR_NOT_CREATED");

        // -----------------------
        // 5. Deploy PuppetV2Pool
        // -----------------------
        pool = new PuppetV2Pool(
            address(weth),
            address(token),
            pair,
            address(factory)
        );

        // -----------------------
        // 6. Mint tokens to pool and attacker
        // -----------------------
        token.mint(address(pool), 1_000_000 ether); // pool liquidity
        token.mint(attacker, 10_000 ether);          // attacker initial supply

        // Give attacker ETH also
        vm.deal(attacker, 20 ether);
    }

    // Optional test to ensure setup works
    function testSetup() public {
        assertEq(token.balanceOf(address(pool)), 1_000_000 ether);
        assertEq(token.balanceOf(attacker), 10_000 ether);
        assertTrue(pair != address(0));
    }

    receive() external payable {}
}

