// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
	constructor() ERC20("USDT", "USDT") {
		_mint(msg.sender, 1000000 * 10 ** decimals());
	}

	function decimals() public view virtual override returns (uint8) {
		return 6;
	}
}