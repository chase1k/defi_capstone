// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "../src/exchange/ERC20Mint.sol";
import "../src/exchange/Factory.sol";
import "../src/exchange/Router.sol";
import "../src/exchange/Pair.sol";

contract ExchangeTest is Test {
    ERC20Mint tokenA;
    ERC20Mint tokenB;
    Factory factory;
    Router router;

    address alice = address(0xA1);
    address bob = address(0xB1);

    function setUp() public {
        tokenA = new ERC20Mint("Token A", "TKA");
        tokenB = new ERC20Mint("Token B", "TKB");

        factory = new Factory();
        router = new Router(address(factory));
    }

    function testMintApproveAddLiquidityAndSwap() public {
        // Mint tokens
        tokenA.mint(alice, 1000 ether);
        tokenB.mint(alice, 1000 ether);
        tokenA.mint(bob, 100 ether);

        // Alice approves router
        vm.prank(alice);
        tokenA.approve(address(router), 500 ether);
        vm.prank(alice);
        tokenB.approve(address(router), 500 ether);

        // Add liquidity
        vm.prank(alice);
        uint256 liquidity = router.addLiquidity(address(tokenA), address(tokenB), 500 ether, 500 ether, alice);
        assertGt(liquidity, 0);

        // check reserves
        address pairAddr = factory.getPair(address(tokenA), address(tokenB));
        Pair pair = Pair(pairAddr);
        (uint112 r0, uint112 r1) = pair.getReserves();
        assertGt(r0, 0);
        assertGt(r1, 0);

        // Bob approves router
        vm.prank(bob);
        tokenA.approve(address(router), 10 ether);

        // Swap
        vm.prank(bob);
        uint256 amountOut = router.swapExactTokensForTokens(10 ether, 0, address(tokenA), address(tokenB), bob);

        //emit log_named_uint("Bob TKB balance", tokenB.balanceOf(bob));
        //emit log_named_uint("Pair reserves0", r0);
        //emit log_named_uint("Pair reserves1", r1);

        //assertGt(tokenB.balanceOf(bob), 0);
    }
}
