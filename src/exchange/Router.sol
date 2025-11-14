// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Router is IUniswapV2Router {
    IUniswapV2Factory public factory;

    constructor(address _factory) {
        factory = IUniswapV2Factory(_factory);
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB, address to)
        external
        override
        returns (uint256 liquidity)
    {
        address pair = factory.getPair(tokenA, tokenB);
        if (pair == address(0)) pair = factory.createPair(tokenA, tokenB);

        // pull tokens from user
        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);

        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenA,
        address tokenB,
        address to
    ) external override returns (uint256 amountOut) {
        address pair = factory.getPair(tokenA, tokenB);
        require(pair != address(0), "PAIR_DOES_NOT_EXIST");

        // pull tokens from user
        IERC20(tokenA).transferFrom(msg.sender, pair, amountIn);

        (uint112 reserve0, uint112 reserve1) = IUniswapV2Pair(pair).getReserves();
        if (tokenA < tokenB) {
            amountOut = (amountIn * reserve1) / reserve0;
            require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT");
            IUniswapV2Pair(pair).swap(0, amountOut, to);
        } else {
            amountOut = (amountIn * reserve0) / reserve1;
            require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT");
            IUniswapV2Pair(pair).swap(amountOut, 0, to);
        }
    }
}
