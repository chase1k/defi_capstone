// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ERC20Mint.sol";
import "../src/Factory.sol";
import "../src/Router.sol";

contract DeployExchange is Script {
    function run() external {
        vm.startBroadcast();

        // 1️⃣Deploy two mintable tokens
        ERC20Mint tokenA = new ERC20Mint("Token A", "TKA");
        ERC20Mint tokenB = new ERC20Mint("Token B", "TKB");

        //  Deploy the factory
        Factory factory = new Factory();

        //  Deploy the router with the factory address
        Router router = new Router(address(factory));

        //  Print deployed contract addresses
        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("Factory:", address(factory));
        console.log("Router:", address(router));

        vm.stopBroadcast();
    }
}

