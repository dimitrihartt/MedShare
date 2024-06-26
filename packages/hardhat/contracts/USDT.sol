// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT is ERC20, Ownable {
	constructor(
		address initialOwner
	) ERC20("USDT", "USDT") Ownable(initialOwner) {
		_mint(msg.sender, 1000000 * 10 ** decimals());
	}

	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}

	function decimals() public view virtual override returns (uint8) {
		return 6;
	}
}
