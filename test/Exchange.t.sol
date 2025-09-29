// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ERC20Mint.sol";
import "../src/Factory.sol";
import "../src/Router.sol";
import "../src/SimplePair.sol";

contract ExchangeTest is Test {
    ERC20Mint tokenA;
    ERC20Mint tokenB;
    Factory factory;
    Router router;
    address alice;
    address bob;

    function setUp() public {
        alice = address(0x1);
        bob = address(0x2);

        tokenA = new ERC20Mint("Token A", "A");
        tokenB = new ERC20Mint("Token B", "B");
        factory = new Factory();
        router = new Router(address(factory));
    }

    function testCreatePairAndAddLiquidityAndSwap() public {
        // create pair
        address pair = factory.createPair(address(tokenA), address(tokenB));
        assertTrue(pair != address(0));

        // mint tokens to alice
        tokenA.mint(alice, 1_000_000 ether);
        tokenB.mint(alice, 1_000_000 ether);

        // Alice approves router
        vm.startPrank(alice);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);

        // add liquidity 1000 A and 1000 B
        router.addLiquidity(address(tokenA), address(tokenB), 1000 ether, 1000 ether, alice);

        // check reserves > 0
        (uint112 r0, uint112 r1) = SimplePair(pair).getReserves();
        assertEq(uint(r0) > 0, true);
        assertEq(uint(r1) > 0, true);

        // do a swap: alice swaps 10 A for B, send to bob
        tokenA.mint(bob, 20 ether);
        // bob approves router
        vm.stopPrank();
        vm.startPrank(bob);
        tokenA.approve(address(router), type(uint).max);

        uint balBefore = tokenB.balanceOf(bob);
        router.swapExactTokensForTokens(address(tokenA), address(tokenB), 10 ether, bob);
        uint balAfter = tokenB.balanceOf(bob);
        assertTrue(balAfter > balBefore);
        vm.stopPrank();
    }
}

