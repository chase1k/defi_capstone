pragma solidity ^0.8.19;


import "./ERC20Mint.sol";

contract NaiveReceiverLenderPool {

	ERC20Mint public immutable token;

	uint256 private constant FIXED_FEE = 1 ether;

	event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);

	error NotEnoughTokensInPool();
	error FlashLoanNotRepaid(); 

	constructor(address _token) {
		token = ERC20Mint(_token);
	}

	function flashLoan(address borrower, uint256 amount) external {
		uint256 balanceBefore = token.balnceOf(address(this));
		
		if (balanceBefore < amount) {
			revert NotEnoughTokensInPool();
		}

		require(
			token.balanceOf(borrower) >= FIXED_FEE, "Borrower doesn't have enough for fee"
		);
		
		token.transfer(borrower, amount);
		
		IFlashLoanReceiver(borrower).receiveFlashLoan(amount);
		
			
