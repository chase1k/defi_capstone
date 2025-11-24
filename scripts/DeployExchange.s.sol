// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/exchange/ERC20Mint.sol";
import "../src/exchange/Factory.sol";
import "../src/exchange/Router.sol";

contract DeployExchange is Script {
    function run() external {
        vm.startBroadcast();

        ERC20Mint tokenA = new ERC20Mint("Token A", "TKA");
        ERC20Mint tokenB = new ERC20Mint("Token B", "TKB");

        Factory factory = new Factory();

        Router router = new Router(address(factory));

        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("Factory:", address(factory));
        console.log("Router:", address(router));

        vm.stopBroadcast();
    }
}
