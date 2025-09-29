// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Factory.sol";
import "./SimplePair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Router {
    address public factory;

    constructor(address _factory) {
        factory = _factory;
    }

    // add liquidity: caller must approve tokens to router
    function addLiquidity(address tokenA, address tokenB, uint amountA, uint amountB, address to) external {
        address pair = Factory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "PAIR_NOT_EXISTS");

        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
        SimplePair(pair).mint(to);
    }

    // swap exact input: swap tokenA -> tokenB using pair
    function swapExactTokensForTokens(address tokenIn, address tokenOut, uint amountIn, address to) external {
        address pair = Factory(factory).getPair(tokenIn, tokenOut);
        require(pair != address(0), "PAIR_NOT_EXISTS");

        // transfer tokenIn to pair
        IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);

        // compute reserves and do simple output calculation using constant product (no fees)
        (uint112 reserve0, uint112 reserve1) = SimplePair(pair).getReserves();
        (address token0, ) = (SimplePair(pair).token0(), SimplePair(pair).token1());
        uint balance0 = IERC20(token0).balanceOf(pair);
        uint balance1 = IERC20(SimplePair(pair).token1()).balanceOf(pair);

        // determine amounts after input:
        // If tokenIn == token0 then amount0In = amountIn and compute amount1Out:
        if (tokenIn == token0) {
            uint amount0In = amountIn;
            uint newBalance0 = balance0;
            uint k = uint(reserve0) * uint(reserve1);
            // newBalance1 = k / newBalance0;
            uint newBalance1 = k / newBalance0;
            require(newBalance1 < balance1, "NO_OUTPUT");
            uint amount1Out = balance1 - newBalance1;
            SimplePair(pair).swap(0, amount1Out, to);
        } else {
            uint amount1In = amountIn;
            uint newBalance1 = balance1;
            uint k = uint(reserve0) * uint(reserve1);
            uint newBalance0 = k / newBalance1;
            require(newBalance0 < balance0, "NO_OUTPUT");
            uint amount0Out = balance0 - newBalance0;
            SimplePair(pair).swap(amount0Out, 0, to);
        }
    }
}

