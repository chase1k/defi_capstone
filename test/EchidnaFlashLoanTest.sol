pragma solidity ^0.8.19;

import "./../src/ERC20Mint.sol";
import "./../src/VulnerablePool.sol";


contract EchidnaFlashLoanTest is IERC3156FlashBorrower {
	ERC20Mint public token;
	VulnerablePool public vault;

	uint256 constant TOKENS_IN_VAULT = 1000000e18;
	uint256 constant INITIAL_ATTACKER_BALANCE = 10e18;

	constructor(){
		token = new ERC20Mint("Test Token", "TEST");
		vault = new VulnerablePool(token, "VAult token", "vTEST", msg.sender);

		token.mint(address(this), TOKENS_IN_VAULT);
		token.approve(address(vault), TOKENS_IN_VAULT);
		vault.deposit(TOKENS_IN_VAULT, address(this));
		token.mint(address(0x10000), INITIAL_ATTACKER_BALANCE);
	}

	function onFlashLoan (
		address initiator,
		address _token,
		uint256 amount,
		uint256 fee,
		bytes calldata
	) external returns (bytes32) {
		require (
			initiator == address(this) &&
			msg.sender == address(vault) &&
			_token == address(vault.asset()) &&
			fee == 0
		);

		IERC20(_token).approve(address(vault), amount);
		return keccak256("ERC3156FlashBorrower.onFlashLoan");
	}

	function action_deposit(uint256 amount) public {
        if (amount == 0 || amount > 1000 ether) return;
        
        uint256 balance = token.balanceOf(msg.sender);
        if (balance < amount) return;
        
        token.approve(address(vault), amount);
        vault.deposit(amount, msg.sender);
    	
	}
	
	function action_withdraw(uint256 shares) public {
        	if (shares == 0) return;
        
        	uint256 myShares = vault.balanceOf(msg.sender);
        	if (myShares < shares) return;
        
        	vault.redeem(shares, msg.sender, msg.sender);
    	}
	
	function action_donate(uint256 amount) public {
		if (amount == 0) return;

		uint256 balance = token.balanceOf(msg.sender);
		if (balance < amount) return;

		token.transfer(address(vault), amount);
	}

	function action_transfer(address to, uint256 amount) public {
		if (to == address(0) || to == address(vault)) return;
		if (amount == 0) return;

		uint256 balance = token.balanceOf(msg.sender);
		if (balance < amount) return;
		
		token.transfer(to, amount);
	}
		

	function echidna_test_flashloan() public returns (bool) {
		vault.flashLoan(this,address(token), 10e18, "");
		return true;
	}
}


