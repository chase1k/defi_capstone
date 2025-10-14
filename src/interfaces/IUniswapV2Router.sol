// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB,
        address to
    ) external returns (uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address tokenA,
        address tokenB,
        address to
    ) external returns (uint amountOut);
}

