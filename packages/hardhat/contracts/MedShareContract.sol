//SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Using Chainlink for automated value of xagusd and ethusd
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Setting an Interface to call ERC20 USDT Contract on Mainnet
interface IContractUSDT {
	function balanceOf(address) external pure returns (uint256);

	// You can check if you have correctly allowed the right amount to be spent
	function allowance(address, address) external pure returns (uint256);

	// Someone that has allowance can send money to himself
	function transfer(address, uint256) external payable returns (bool);

	function approve(address, uint256) external payable returns (bool);

	// This can be used to transfer from the contract to Another Contract/EOA
	function transferFrom(
		address,
		address,
		uint256
	) external payable returns (bool);
}

/// @custom:security-contact dimitrileite@hotmail.com
contract MedShareContract is ERC20, ERC20Burnable, Ownable {
	/**
	 * Network: Ethereum Mainnet
	 * This Contract uses Chainlink as its Oracle:
	 * Aggregator: XAG/USD
	 * Address: 0x379589227b15F1a12195D3f2d90bBc9F31f95235
	 * Agregator: ETH/USD
	 * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
	 * Obs.: If agragators will not be working in the future
	 * we will keep track of USD and Ether Prices manually or
	 * we are going to the next version of this contract.
	 */
	AggregatorV3Interface internal dataFeedXagUsd;
	AggregatorV3Interface internal dataFeedEthUsd;

	uint256 public xagUsdPrice;
	uint256 public ethUsdPrice;
	uint256 public mdstUsdPriceWithCents;

	// This is a type that represents some God`s kingdom principles
	struct Misc {
		uint256 twelfth; // The twelfth
		uint256 tenth; // The tenth
		uint256 fifth; // The fifth
		uint256 halfShekelConst; // This is equivalent to one halfShekel 7.1g of Silver.
	}

	Misc misc = Misc(12, 10, 5, 250529287);

	// This declares a state variable that
	// stores the balance of Ether Invested for each possible address in Wei.
	mapping(address => uint256) public amountInvestedInWeiOf;

	// This declares a state variable that
	// stores the balance of USDT Invested for each possible address
	// in Usd with 6 decimals.
	mapping(address => uint256) public amountInvestedInUSDTOf;

	// This looks like the little box that you see in front of
	// every Mc'Donalds' cachier machine to receive tips.
	uint256 public reserveInUsdFromRemaindersWithCents;

	// USDT Contract Address on Mainnet
	address public USDTContractAddress;

	constructor(
		address initialOwner		
	) ERC20("MedShareToken", "MDST") Ownable(initialOwner) {		
		// ethUsdPrice = getEthUsdLatestPrice();
		// xagUsdPrice = getXagUsdLatestPrice();		
		// USDTContractAddress = usdtContract;

		// Initial prices:
		ethUsdPrice = 334264228341;
		xagUsdPrice = 2956000000;
		mdstUsdPriceWithCents = 730;
	}

	/**
	 * MedShareToken (MDST) has only 02 decimal places,
	 * so we've used: amount * 10**decimals()
	 * XagUsd and EthUsd prices have 8 decimal places.
	 */
	function decimals() public view virtual override returns (uint8) {
		return 2;
	}

	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}

	/**
	 * Sets Chainlink agregators manually
	 */
	function setAgregatorsManually(
		address xagusd,
		address ethusd
	) public onlyOwner {
		//Mainnet : 0x379589227b15F1a12195D3f2d90bBc9F31f95235
		dataFeedXagUsd = AggregatorV3Interface(xagusd);
		//Mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
		dataFeedEthUsd = AggregatorV3Interface(ethusd);
	}

	/**
	 * Sets XagUsd price with 08 decimal places manually
	 */
	function setXagUsdManually(uint256 price) public onlyOwner {
		xagUsdPrice = price;
	}

	/**
	 * Sets EthUsd price with 08 decimal places manually
	 */
	function setEthUsdManually(uint256 price) public onlyOwner {
		ethUsdPrice = price;
	}

	/**
	 * Returns the latest XagUsd price.
	 */
	function getXagUsdLatestPrice() public view returns (uint256) {
		// prettier-ignore
		(
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeedXagUsd.latestRoundData();
		return uint256(answer);
	}

	/**
	 * Returns the latest EthUsd price.
	 */
	function getEthUsdLatestPrice() public view returns (uint256) {
		// prettier-ignore
		(
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeedEthUsd.latestRoundData();
		return uint256(answer);
	}

	function investWithEther() external payable {
		uint256 amount = msg.value;

		// Updating the sender's invested Ether balance (in Wei)
		uint256 fromBalance = amountInvestedInWeiOf[msg.sender];
		amountInvestedInWeiOf[msg.sender] = fromBalance + amount;

		// Exchange Ether to MDST (Price of Half-Shekel of Silver)
		// We have 18 decimal places from ether to wei
		// and 8 decimal places for ethUsdPrice
		// which gives us 26 decimal places in total,
		// as we want 2 decimal places for cents,
		// then we need to divide by 10**24
		uint256 amountInUsdWithCents = (amount * ethUsdPrice) / 10 ** 24;

		// xagUsdPrice has 8 decimal places
		// and the Const has 9 decimal places
		// which gives us 17 decimal places in total,
		// as we want 2 decimal places for cents,
		// then we need to divide by 10**15
		mdstUsdPriceWithCents = (xagUsdPrice * misc.halfShekelConst) / 10 ** 15;

		uint256 amountOfMdsts = amountInUsdWithCents / mdstUsdPriceWithCents;

		// Setting the reserve with the remainder of the above division in USD with cents.
		reserveInUsdFromRemaindersWithCents +=
			amountInUsdWithCents %
			mdstUsdPriceWithCents;

		_mint(msg.sender, amountOfMdsts * 10 ** decimals());
	}

	/**
	 * Sets USDT contract address manually (ERC-20) (only owner)
	 */
	function setUSDTContractAddress(address addr) public onlyOwner {
		USDTContractAddress = addr;
	}

	/**
	 * Gets an account's balance in USDT
	 */
	function getBalanceInUSDT(address addr) public view returns (uint256) {
		return IContractUSDT(USDTContractAddress).balanceOf(addr);
	}

	/**
	 * Gets this contract's supply of USDT
	 */
	function getUSDTSupply() public view returns (uint256) {
		return IContractUSDT(USDTContractAddress).balanceOf(address(this));
	}

	/**
	 * Sets the amount allowed for an account to withdraw USDT's
	 */
	function setAllowanceForAnAccountInUSDT(
		address userAddr,
		uint256 amount
	) private returns (bool) {
		return IContractUSDT(USDTContractAddress).approve(userAddr, amount);
	}

	/**
	 * Gets the allowance in USDT
	 */
	function getAllowanceInUSDT() public view returns (uint256) {
		return
			IContractUSDT(USDTContractAddress).allowance(
				msg.sender,
				address(this)
			);
	}

	/**
	 * Invest with USDT with 6 decimals
	 */
	function investWithUSDT(uint256 amount) external payable {
		uint allowance = getAllowanceInUSDT();
		require(
			allowance >= amount,
			"You need to approve this contract's address, with at least the desired amount to be invested, in the USDT Contract."
		);

		// Interacting with USDT Contract:
		// Transfer from the user to the contract
		// the amount specified and previously approved
		bool sent = IContractUSDT(USDTContractAddress).transferFrom(
			msg.sender,
			address(this),
			amount
		);
		require(
			sent,
			"Unfortunately the transfer was not completed. No funds were transfered."
		);

		// Updating the sender's invested USDT balance (in USDT with 6 decimals)
		uint256 fromBalance = amountInvestedInUSDTOf[msg.sender];
		amountInvestedInUSDTOf[msg.sender] = fromBalance + amount;

		// xagUsdPrice has 8 decimal places
		// and the Const has 9 decimal places
		// which gives us 17 decimal places in total,
		// as we want 2 decimal places for cents,
		// then we need to divide by 10**15
		mdstUsdPriceWithCents = (xagUsdPrice * misc.halfShekelConst) / 10 ** 15;

		// USTD has 6 decimal places
		// as we want it to have 2 decimal places
		// so we need to divide it by 10**4
		uint256 amountInUsdtWithOnlyCents = amount / 10 ** 4;

		uint256 amountOfMdsts = amountInUsdtWithOnlyCents /
			mdstUsdPriceWithCents;

		// Setting the reserve with the remainder of the above division in USD with cents.
		reserveInUsdFromRemaindersWithCents +=
			amountInUsdtWithOnlyCents %
			mdstUsdPriceWithCents;

		_mint(msg.sender, amountOfMdsts * 10 ** decimals());
	}

	/**
	 * Withdraw your Investment in USDT with 6 decimals.
	 * Initially we are going to issue USDT back to those
	 * that had invested in USDT.
	 */
	function withdrawInUSDT(uint256 amount) external payable {
		// Verify how much the user had invested in USDT
		uint256 amountInvested = amountInvestedInUSDTOf[msg.sender];

		// Require that the value the user wants to withdraw is less or equals the value he had invested.
		require(
			amountInvested >= amount,
			"You have not invested enough USDT to withdraw."
		); // If this is the case, the contract will not send back any USDT to the user, because the user did not invest enough USDT to withdraw the desired amount of USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the first place, it is not a good idea to withdraw USDT to the user if he did not invest enough USDT, 6 decimals, in the
	}

	//updateContractBalances(amount);

	/*
    Which function is called, fallback() or receive()?
           send Ether
               |
         msg.data is empty?
              /       \
            yes        no
            /           \
    receive() exists?  fallback()
          /   \
        yes    no
        /       \
    receive()   fallback()
    */

	// Function to receive Ether. msg.data must be empty
	receive() external payable {}

	// Fallback function is called when msg.data is not empty
	fallback() external payable {}

	function getContractsBalanceInWei() public view returns (uint256) {
		return address(this).balance;
	}

	function sendViaTransfer(address payable _to) public payable {
		// This function is no longer recommended for sending Ether.
		_to.transfer(msg.value);
	}

	function sendViaSend(address payable _to) public payable {
		// Send returns a boolean value indicating success or failure.
		// This function is not recommended for sending Ether.
		bool sent = _to.send(msg.value);
		require(sent, "Failed to send Ether");
	}

	function sendViaCall(address payable _to) public payable {
		// Call returns a boolean value indicating success or failure.
		// This is the current recommended method to use.
		(bool sent, bytes memory data) = _to.call{ value: msg.value }("");
		require(sent, "Failed to send Ether");
	}
}
