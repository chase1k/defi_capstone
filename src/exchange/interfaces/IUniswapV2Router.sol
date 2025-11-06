// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV2Router {
    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB, address to)
        external
        returns (uint256 liquidity);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenA,
        address tokenB,
        address to
    ) external returns (uint256 amountOut);
}

