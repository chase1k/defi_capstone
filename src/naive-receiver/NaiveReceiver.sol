pragma solidity ^0.8.19;


import "./ERC20Mint.sol";


abstract contract Multicall {
	function multicall(bytes [] calldata data) external virtual returns (bytes[] memory results) {
		results = new bytes[](data.length);
		for (uint256 i = 0; i < data.length; i++) {
			(bool success, bytes memory result) = address(this).delegatecall(data[i]);
			if (!success) {

				assembly {
					revert(add(result, 32), mload(result))
				}
			}

			results[i] = result;

		}

		return results;
	}
}

contract NaiveReceiverLenderPool is Multicall {

	ERC20Mint public immutable token;

	uint256 private constant FIXED_FEE = 1 ether;

	error RepayFailed(); 

	constructor(address _token) {
		token = ERC20Mint(_token);
	}

	function flashLoan(address borrower, uint256 amount) external {
		uint256 balanceBefore = token.balanceOf(address(this));

		token.transfer(borrower, amount);
		
		if (borrower.code.length > 0) {
			INaiveReceiverReceiver(borrower).onFlashLoan(
				msg.sender,
				address(token),
				amount,
				FIXED_FEE,
				""
			);
		}

		if (token.balanceOf(address(this)) < balanceBefore + FIXED_FEE) {
			revert RepayFailed();
		}
	}
	
	function fixedFee() external pure returns (uint256) {
		return FIXED_FEE;
	}
}
	
interface INaiveReceiverReceiver {
	function onFlashLoan (
		address operator,
		address token,
		uint256 amount,
		uint256 fee,
		bytes calldata data
	) external returns (bool);
}

contract FlashLoanReceiver is INaiveReceiverReceiver {
	NaiveReceiverLenderPool public immutable pool;
	ERC20Mint public immutable token;

	error  UnsupportedToken(address token);
	error CallbackNotAllowed();

	constructor (address _pool) payable {
		pool = NaiveReceiverLenderPool(_pool);
		token = ERC20Mint(pool.token());
	}

	function onFlashLoan (
		address,
		address _token,
		uint256 amount,
		uint256 fee,
		bytes calldata
	) external returns (bool) {
		if (msg.sender != address(pool)) {
			revert CallbackNotAllowed();
		}

		if(_token != address(token)) {
			revert UnsupportedToken(_token);
		}

		token.approve(address(pool), amount + fee);

		return true;
	}

	function withdraw() external {
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}
}


