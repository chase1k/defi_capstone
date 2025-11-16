// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20Mint} from "src/exchange/ERC20Mint.sol";
import {INonfungiblePositionManager} from "src/puppet-v3/INonfungiblePositionManager.sol";
import {PuppetV3Pool} from "src/puppet-v3/PuppetV3Pool.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IHevm {
    function warp(uint256 newTimestamp) external;
}

contract PuppetV3Echidna {
    address constant HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
    IHevm constant hevm = IHevm(HEVM_ADDRESS);

    uint256 constant UNISWAP_INITIAL_TOKEN_LIQUIDITY = 100e18;
    uint256 constant UNISWAP_INITIAL_WETH_LIQUIDITY = 100e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 110e18;
    uint256 constant LENDING_POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;
    uint24 constant FEE = 3000;

    IUniswapV3Factory uniswapFactory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager positionManager =
        INonfungiblePositionManager(payable(0xC36442b4a4522E871399CD717aBDD847Ab11FE88));
    WETH weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    ERC20Mint public token;
    PuppetV3Pool public lendingPool;
    IUniswapV3Pool public uniswapPool;
    ISwapRouter router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    uint256 public initialWETHRequired;
    uint256 public initialBlockTimestamp;
    bool public initialized;
    address public constant recovery = address(0xdeadbeef);

    constructor() payable {
        require(address(this).balance >= UNISWAP_INITIAL_WETH_LIQUIDITY, "Insufficient ETH balance");

        token = new ERC20Mint("MyToken", "MTK");

        bool isWethFirst = address(weth) < address(token);
        address token0 = isWethFirst ? address(weth) : address(token);
        address token1 = isWethFirst ? address(token) : address(weth);
        positionManager.createAndInitializePoolIfNecessary{value: 0}({
            token0: token0, token1: token1, fee: FEE, sqrtPriceX96: _encodePriceSqrt(1, 1)
        });

        uniswapPool = IUniswapV3Pool(uniswapFactory.getPool(address(weth), address(token), FEE));
        uniswapPool.increaseObservationCardinalityNext(40);

        weth.approve(address(positionManager), type(uint256).max);
        token.approve(address(positionManager), type(uint256).max);
        token.mint(
            address(this),
            UNISWAP_INITIAL_TOKEN_LIQUIDITY + PLAYER_INITIAL_TOKEN_BALANCE + LENDING_POOL_INITIAL_TOKEN_BALANCE
        );
        weth.deposit{value: UNISWAP_INITIAL_WETH_LIQUIDITY}();

        positionManager.mint{value: 0}(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                tickLower: -60,
                tickUpper: 60,
                fee: FEE,
                recipient: address(this),
                amount0Desired: UNISWAP_INITIAL_WETH_LIQUIDITY,
                amount1Desired: UNISWAP_INITIAL_TOKEN_LIQUIDITY,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        lendingPool = new PuppetV3Pool(weth, token, uniswapPool);
        token.transfer(address(lendingPool), LENDING_POOL_INITIAL_TOKEN_BALANCE);
        token.transfer(address(this), PLAYER_INITIAL_TOKEN_BALANCE);

        hevm.warp(block.timestamp + 3 days);
        initialBlockTimestamp = block.timestamp;

        initialWETHRequired = lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE);
    }

    function echidna_no_price_manipulation() public view returns (bool) {
        uint256 timePassed = block.timestamp - initialBlockTimestamp;

        if (timePassed < 115 seconds) {
            return true; // Not enough time for TWAP period
        }

        uint256 currentWETHRequired = lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE);

        // Even a 1% change is a price manipulation
        return currentWETHRequired >= (initialWETHRequired * 99) / 100;
    }

    function echidna_recovery_has_exploited_tokens() public view returns (bool) {
        uint256 poolBalance = token.balanceOf(address(lendingPool));
        uint256 recoveryBalance = token.balanceOf(recovery);
        uint256 timePassed = block.timestamp - initialBlockTimestamp;

        // Pool needs to be drained
        if (poolBalance >= LENDING_POOL_INITIAL_TOKEN_BALANCE) {
            return true;
        }

        uint256 poolDrained = LENDING_POOL_INITIAL_TOKEN_BALANCE - poolBalance;

        // Ignore mints
        if (recoveryBalance > poolDrained) {
            return true;
        }

        if (poolDrained > 0 && recoveryBalance > PLAYER_INITIAL_TOKEN_BALANCE && timePassed >= 115 seconds) {
            return false;
        }

        return true;
    }

    function wait(uint256 secondsToWait) public {
        hevm.warp(block.timestamp + secondsToWait);
    }

    function attemptSwap(uint256 amountIn) public {
        if (amountIn == 0) return;
        if (amountIn > token.balanceOf(address(this))) return;

        token.approve(address(router), amountIn);
        router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(weth),
                fee: FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function attemptBorrow(uint256 borrowAmount) public {
        if (borrowAmount == 0) return;
        if (borrowAmount > LENDING_POOL_INITIAL_TOKEN_BALANCE) return;
        if (token.balanceOf(address(lendingPool)) < borrowAmount) return;

        uint256 wethRequired = lendingPool.calculateDepositOfWETHRequired(borrowAmount);

        // Only allow borrow if price has been manipulated (WETH required is less than initial)
        uint256 initialWETHForAmount = (initialWETHRequired * borrowAmount) / LENDING_POOL_INITIAL_TOKEN_BALANCE;
        if (wethRequired >= initialWETHForAmount) return;

        // Calculate how much ETH we need to deposit
        uint256 wethBalance = weth.balanceOf(address(this));
        uint256 ethBalance = address(this).balance;
        weth.deposit{value: wethRequired - wethBalance}();
        weth.approve(address(lendingPool), wethRequired);
        lendingPool.borrow(borrowAmount);
        token.transfer(recovery, borrowAmount);
    }

    function _encodePriceSqrt(uint256 reserve1, uint256 reserve0) private pure returns (uint160) {
        return uint160(FixedPointMathLib.sqrt((reserve1 * 2 ** 96 * 2 ** 96) / reserve0));
    }
}
