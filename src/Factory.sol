// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract Factory is IUniswapV2Factory {
    mapping(address => mapping(address => address)) public override getPair;

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        require(getPair[tokenA][tokenB] == address(0), "PAIR_EXISTS");

        Pair newPair = new Pair(tokenA, tokenB);
        pair = address(newPair);

        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
    }
}

