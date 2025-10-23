//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19

import {IERC3156FlashBorrower, IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol"

contract VulnerablePool is IERC3156FlashLender, ReentrancyGuard, Ownable, ERC4626, Pausable {
	uint256 public constant FEE_FACTOR = 500;
	uint256 public constant GRACE_PERIOD = 30 days;

	uint256 public immutable deploymentTime;
	address public feeRecipent;

	error InvalidAmount(uint256 amount);
	error InvalidBalance();
	error CallbackFailed();
	error UnsupportedToken();


	event FlashLoanExecuted(address indexed receiver, uint256 amount, uint256 fee);
	event FeeRecipientUpdataed (address indexed newFeeRecipient);

	constructor(
		IERC20 _asset,
		string memory _name,
		string memory _symbol,
		address _feeRecipient
	)
		ERC4626(_asset)
		ERC20(_name , _symbol)
		Ownable(msg.sender)
	{
		deploymentTime = block.timestamp;
		feeRecipient = _feeRecipient;
	}

	function maxFlashLoan(address token)
		public
		view
		override
		returns (uint256)
	{
		if (token != asset()) return 0;
		return totalAssets();
	}

	function flashFee(address token, uint256 amount)
		public
		view
		override
		returns (uint256 fee)
	{
		if (token != asset()) revert UnsupportedToken();

		if(block.timestamp < deploymentTime + GRACE_PERIOD && amount <= maxFlashLoan(token)){
			return 0;
		}
		return (amount * FEE_FACTOR) / 10000;
	}

	function flashLoan(
		IERC3156FlashBorrower reciever,
		address token,
		uint256 amount,
		bytes calldata data
	)
		external
		override
		nonReentrant
		returns (bool)
	{

		if (amount == 0) revert InvalidAmount();
		if (token != asset()) revert UnsupportedToken();

		uint256 balanceBefore = totalAssets();

		if(convertToAssets(totalSupply()) != balanceBefore) {
			revert InvalidBalance();
		}

		uint256 fee = flashFee(token, amount);
	
		IERC20(token.transfer(address(receiver), amount);

		if (receiver.onFlashLoan(msg.sender, token, amount, fee, data)
		    != keccak256("ERC3156FlashBorrower.onFlashLoan")
	    	) {
			revert CallbackFailed();
		}

		IERC20(token).transferFrom(address(receiver), address(this), amount + fee);
		
		if (fee > 0) {
			IERC20(token).transfer(feeRecipient, fee);
		}
		
		emit FlashLoanExecuted(address(receiver), amount, fee);
		return true;
	}


	function totalAssets()
		public
		view
		override
		returns (uint256)
	{
		return IERC20(asset()).balanceOf(address(this));
	}


	function _deposit(
		address caller,
		address receiver,
		uint256 assets,
		uint256 shares
	) internal override nonReentrant whenNotPaused {
		super._deposit(caller, receiver, assets, shares);
	}

	function _withdraw(
		address caller,
		address receiver,
		address owner,
		uint256 assets,
		uint256 shares
	) internal override nonReentrant {
		super._withdraw(caller, receiver, owner, assets, shares);
	}


	function setFeeRecipient(address _feeRecipient) external onlyOwner {
		require(_feeRecipient != address(0), "Invalid address");
		feeRecipient = _feeRecipient;
		emit FeeRecipientUpdated(_feeRecipient);
	}

	function setPause(bool flag) external onlyOwner {
		if (flag) {
			_pause();
		} else {
			_unpause();
		}
	}

	function execute(address target, bytes memory data)
		external
		onlyOwner
		whenPaused
		returns (bytes memory)
	{
		(bool success, bytes memory result) = target.delegatecall(data);
		require(success, "Delegatecall failed");
		return result;
	}


}
