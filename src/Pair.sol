// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract Pair is ERC20, IUniswapV2Pair {
    address public override token0;
    address public override token1;

    uint112 private reserve0;
    uint112 private reserve1;

    uint constant public MINIMUM_LIQUIDITY = 1000;

    constructor(address _token0, address _token1) ERC20("LP Token", "LP") {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() external view override returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function mint(address to) external override returns (uint liquidity) {
        uint bal0 = ERC20(token0).balanceOf(address(this)) - reserve0;
        uint bal1 = ERC20(token1).balanceOf(address(this)) - reserve1;

        if (totalSupply() == 0) {
            liquidity = sqrt(bal0 * bal1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = _min((bal0 * totalSupply()) / reserve0, (bal1 * totalSupply()) / reserve1);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        reserve0 = uint112(ERC20(token0).balanceOf(address(this)));
        reserve1 = uint112(ERC20(token1).balanceOf(address(this)));
    }

    function burn(address to) external override returns (uint amount0, uint amount1) {
        amount0 = reserve0 / 2;
        amount1 = reserve1 / 2;

        _burn(to, totalSupply() / 2);

        ERC20(token0).transfer(to, amount0);
        ERC20(token1).transfer(to, amount1);

        reserve0 -= uint112(amount0);
        reserve1 -= uint112(amount1);
    }

    function swap(uint amount0Out, uint amount1Out, address to) external override {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT");

        if (amount0Out > 0) ERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) ERC20(token1).transfer(to, amount1Out);

        reserve0 = uint112(ERC20(token0).balanceOf(address(this)));
        reserve1 = uint112(ERC20(token1).balanceOf(address(this)));
    }

    function _min(uint x, uint y) internal pure returns (uint) {
        return x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

