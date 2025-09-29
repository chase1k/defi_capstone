// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SimplePair.sol";

contract Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");

        SimplePair newPair = new SimplePair(token0, token1);
        pair = address(newPair);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
}

