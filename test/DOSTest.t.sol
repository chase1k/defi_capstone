pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ERC20Mint.sol";
import "../src/VulnerablePool.sol";

contract FlashLoanBorrower is IERC3156FlashBorrower {
	address public vault;
	address public token;

	bool public callbackExecuted;
	uint256 public loanAmount;
	uint256 public feeAmount;
	uint256 public executionCount;

	constructor(address _vault, address _token) {
		vault = _vault;
		token = _token;
	}

	function executeFlashLoan(uint256 amount) external returns (bool) {
		return IERC3156FlashLender(vault).flashLoan(
			IERC3156FlashBorrower(this),
			token,
			amount,
			""
		);
	}

	function onFlashLoan(
		address initiator,
		address _token,
		uint256 amount,
		uint256 fee,
		bytes calldata data
	) external override returns (bytes32) {
		require(msg.sender == vault, "Only vault");
		require(_token == token, "Wrong token");
		
		callbackExecuted = true;
		loanAmount = amount;
		feeAmount = fee;
		executionCount++;

		IERC20(_token).approve(vault, amount + fee);

		return keccak256("ERC3156FlashBorrower.onFlashLoan");
	}

	function reset() external {
		callbackExecuted = false;
		loanAmount = 0;
		feeAmount = 0;
	}
}


contract FlashLoanDOSTest is Test {
	ERC20Mint public token;
	VulnerablePool public vault;
	FlashLoanBorrower public borrower;


	address public alice = address(0xA11CE);
	address public bob = address(0xB0B);
	address public attacker = address(0xBAD);
	address public feeRecipient = address(0xFEE);

	function setUp() public {
		token = new ERC20Mint("Test token", "TEST");

		vault = new VulnerablePool(
			token,
			"Vault Token",
			"VTECHTOK",
			feeRecipient
		);

		borrower = new FlashLoanBorrower(address(vault), address(token));

		token.mint(alice, 1000 ether);
		token.mint(bob, 500 ether);
		token.mint(address(borrower), 100 ether);
		token.mint(attacker, 1 ether);

		vm.startPrank(alice);
		token.approve(address(vault), 1000 ether);
		vault.deposit(1000 ether, alice);
		vm.stopPrank();
	}


	function test_InitialSetup() public {

		assertEq(token.balanceOf(alice),0);
		assertEq(token.balanceOf(address(vault)), 1000 ether);

		assertEq(vault.balanceOf(alice), 1000 ether);
		assertEq(vault.totalSupply(), 1000 ether);
		assertEq(vault.totalAssets(), 1000 ether);
	}

	function test_BeforeAttack() public {
		borrower.reset();

		bool success = borrower.executeFlashLoan(100 ether);

		assertTrue(success, "FlashLoan Succeeded");
		assertTrue(borrower.callbackExecuted(), "Callback executed");
		assertEq(borrower.loanAmount(), 100 ether, "Loan amount matched");
		assertEq(borrower.feeAmount(), 0, "Fee is 0 during Grace Period");
		assertEq(borrower.executionCount(), 1, "Execution Count incremented");
	}
}
