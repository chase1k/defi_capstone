// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Token.sol";
import "./ERC20Mint.sol";

interface IERC3156FlashBorrower{
	function onFlashLoan(
		address initiator,
		address token,
		uint256 amount,
		uint fee,
		bytes calldata data
	) external returns (bytes32);
}

interface IERC3156FlashLender {
	function maxFlashLoan(address token) external view returns (uint256);
	function flashFee(address token, uint256 amount) external view returns (uint256);
	function flashLoan(
		IERC3156FlashBorrower receiver,
		address token,
		uint256 amount,
		bytes calldata data
	) external returns (bool);
}



contract VulnerablePool is ERC4626{


}
