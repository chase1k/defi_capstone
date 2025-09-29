// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ERC20Mint.sol";
import "../src/Factory.sol";
import "../src/Router.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        ERC20Mint t1 = new ERC20Mint("Token1", "T1");
        ERC20Mint t2 = new ERC20Mint("Token2", "T2");
        Factory factory = new Factory();
        Router router = new Router(address(factory));

        vm.stopBroadcast();

        // Print addresses in foundry output (cast will show)
    }
}

