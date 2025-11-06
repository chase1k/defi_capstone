// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract Pair is ERC20, IUniswapV2Pair {
    address public override token0;
    address public override token1;

    uint112 private reserve0;
    uint112 private reserve1;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor(address _token0, address _token1) ERC20("LP Token", "LP") {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() external view override returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function mint(address to) external override returns (uint256 liquidity) {
        require(to != address(0), "INVALID_RECEIVER");

        uint256 bal0 = ERC20(token0).balanceOf(address(this));
        uint256 bal1 = ERC20(token1).balanceOf(address(this));

        uint256 amount0 = bal0 - reserve0;
        uint256 amount1 = bal1 - reserve1;

        if (totalSupply() == 0) {
            uint256 _liquidity = sqrt(amount0 * amount1);
            liquidity = _liquidity - MINIMUM_LIQUIDITY;
            _mint(address(this), MINIMUM_LIQUIDITY);
        } else {
            liquidity = _min((amount0 * totalSupply()) / reserve0, (amount1 * totalSupply()) / reserve1);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        // update reserves after mint
        reserve0 = uint112(ERC20(token0).balanceOf(address(this)));
        reserve1 = uint112(ERC20(token1).balanceOf(address(this)));
        emit Mint(msg.sender, amount0, amount1, to);
        emit Sync(reserve0, reserve1);
    }

    function burn(address to) external override returns (uint256 amount0, uint256 amount1) {
        require(to != address(0), "INVALID_RECEIVER");

        // burn implementation
        uint256 _totalSupply = totalSupply();
        uint256 lpBalance = balanceOf(address(this));
        require(lpBalance > 0, "NO_LIQUIDITY");

        // calculate amounts with current bal
        uint256 bal0 = ERC20(token0).balanceOf(address(this));
        uint256 bal1 = ERC20(token1).balanceOf(address(this));

        amount0 = (lpBalance * bal0) / _totalSupply;
        amount1 = (lpBalance * bal1) / _totalSupply;

        _burn(address(this), lpBalance);
        ERC20(token0).transfer(to, amount0);
        ERC20(token1).transfer(to, amount1);

        reserve0 = uint112(ERC20(token0).balanceOf(address(this)));
        reserve1 = uint112(ERC20(token1).balanceOf(address(this)));
        emit Burn(msg.sender, amount0, amount1, to);
        emit Sync(reserve0, reserve1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external override {
        require(to != address(0), "INVALID_RECEIVER");
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT");

        (uint112 _reserve0, uint112 _reserve1) = (reserve0, reserve1);

        require(amount0Out < _reserve0 && amount1Out < _reserve1, "INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);

        // update reserves after swap
        uint256 newBal0 = ERC20(token0).balanceOf(address(this));
        uint256 newBal1 = ERC20(token1).balanceOf(address(this));

        reserve0 = uint112(newBal0);
        reserve1 = uint112(newBal1);

        emit Swap(msg.sender, _reserve0 - newBal0, _reserve1 - newBal1, amount0Out, amount1Out, to);
        emit Sync(reserve0, reserve1);
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
