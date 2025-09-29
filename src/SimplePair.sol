// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimplePair is ERC20 {
    address public token0;
    address public token1;

    uint112 private reserve0; // uses uint112 like Uniswap for packing
    uint112 private reserve1;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address to);
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor(address _token0, address _token1) ERC20("Simple LP Token", "sLP") {
        token0 = _token0;
        token1 = _token1;
    }

    function _updateReserves(uint112 r0, uint112 r1) private {
        reserve0 = r0;
        reserve1 = r1;
        emit Sync(r0, r1);
    }

    function getReserves() external view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    /// @notice Add liquidity by sending tokens to this contract first, then calling mint()
    function mint(address to) external returns (uint liquidity) {
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - reserve0;
        uint amount1 = balance1 - reserve1;

        if (totalSupply() == 0) {
            liquidity = sqrt(amount0 * amount1);
            _mint(address(0), 1); // burn a tiny token to avoid zero supply edgecases (optional)
            _burn(address(0), 1);
        } else {
            liquidity = min((amount0 * totalSupply()) / reserve0, (amount1 * totalSupply()) / reserve1);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _updateReserves(uint112(balance0), uint112(balance1));
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @notice Remove liquidity by burning LP tokens; caller should have approved this contract
    function burn(address to) external returns (uint amount0, uint amount1) {
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint _totalSupply = totalSupply(); // gas saving

        uint liquidity = balanceOf(address(this));
        require(liquidity > 0, "NO_LIQUIDITY_TO_BURN");

        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        ERC20(token0).transfer(to, amount0);
        ERC20(token1).transfer(to, amount1);

        balance0 = ERC20(token0).balanceOf(address(this));
        balance1 = ERC20(token1).balanceOf(address(this));
        _updateReserves(uint112(balance0), uint112(balance1));
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @notice Swap tokens. Caller must send tokens into pair before calling (or use router below)
    function swap(uint amount0Out, uint amount1Out, address to) external {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1) = (reserve0, reserve1);
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) ERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) ERC20(token1).transfer(to, amount1Out);

        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));

        // Enforce constant product: (balance0 * balance1) >= (reserve0 * reserve1)
        // We allow no fees so require balance0 * balance1 >= reserve0 * reserve1
        require(uint(balance0) * uint(balance1) >= uint(_reserve0) * uint(_reserve1), "K");

        _updateReserves(uint112(balance0), uint112(balance1));
        emit Swap(msg.sender, 0, 0, amount0Out, amount1Out, to);
    }

    // helpers
    function min(uint x, uint y) private pure returns (uint z) {
        z = x < y ? x : y;
    }
    function sqrt(uint y) private pure returns (uint z) {
        if (y == 0) return 0;
        uint x = y / 2 + 1;
        z = y;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    }
}

