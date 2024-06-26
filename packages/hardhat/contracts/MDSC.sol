// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";
// Useful openzeppelin contracts. Thanks to them!
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
// Useful chainlink contracts. Thanks to them too!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MDSC is ERC20Burnable, Ownable, ERC20Permit {
    
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
    
    // State variables
    uint256 public MDSCPriceWithCentsInUSD;
	address public MedShareContractAddress;

    // This is a type that represents some God`s kingdom principles
    struct Misc {
        uint256 twelfth; // The twelfth
        uint256 tenth; // The tenth
        uint256 fifth; // The fifth
        uint256 halfShekelConst; // This is equivalent to one halfShekel 7.1g of Silver.
    }

    Misc misc = Misc(12, 10, 5, 250529287);

    // Errors
    error FunctionInvalidAtThisScope();

    // Modifiers
    modifier medShareScope() {
        if (msg.sender != MedShareContractAddress)
            revert FunctionInvalidAtThisScope();
        _;
    }

    // Events
    event MintMDSC(address indexed to, uint256 value);
    event BurnMDSC(address indexed from, uint256 value);
    event Catch(address indexed from, uint256 value);
    event RecoverEther(address indexed to, uint256 value);
    event WithdrawUnclaimed(address indexed to, uint256 value);
    event RecoverERC20(address indexed to, uint256 value);

    // This declares a state variable that
    // stores the balance of Ether transfered to this contract
    // by mistake (or not using the right invest function).
    mapping(address => uint256) public amountSentInWeiOf;

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

   constructor(address initialOwner)
        ERC20("MedShare Coin", "MDSC")
        Ownable(initialOwner)
        ERC20Permit("MDSC")
    {
        // Initial price for the MDSC in 2024 = $7.50
        MDSCPriceWithCentsInUSD = 750;
    }

    /**
     * MedShareCoin (MDSC) has only 02 decimal places,
     * so we've used: amount * 10**decimals()
     */
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }
    

    /**
     * Function mint is private and is used autonomously
     */
    function mint(address to, uint256 amount) private {
        _mint(to, amount);
        emit MintMDSC(to, amount);
    }

    /**
     * Function burn is private and is used autonomously
     */
    function burn(address from, uint256 amount) private {
        _burn(from, amount);
        emit BurnMDSC(from, amount);
    }

    /**
     * Sets MedShareContract Address
     */
    function setMedShareContractAddress(address addr) public onlyOwner {
        MedShareContractAddress = addr;
    }

    /**
     * Sets MDSC price with 02 decimal places according to the market
     */
    function setMDSCPrice(uint256 price) external medShareScope {
        MDSCPriceWithCentsInUSD = price;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        catchFunction(msg.sender, msg.value);
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        catchFunction(msg.sender, msg.value);
    }

    /**
     * Gets the contract's balance in Wei (Ether)
     */
    function getContractBalanceInWei() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * Recovers funds invested by mistake in Ether (in Wei)
     */
    function recoverEther() public {
        uint256 fromBalance = amountSentInWeiOf[msg.sender];
        require(fromBalance > 0, "No funds to recover...");
        amountSentInWeiOf[msg.sender] = 0;
        (bool sent, bytes memory data) = msg.sender.call{value: fromBalance}(
            ""
        );
        require(
            sent,
            string(abi.encodePacked("Failed to recover Ether: ", data))
        );
        emit RecoverEther(msg.sender, fromBalance);
    }

    /**
     * Withdraws/Invests lost funds. (This is only made once a year)
     * We are going to withdraw/invest unclaimed lost funds.
     */
    function withdrawUnclaimedEther(uint256 amount) public payable onlyOwner {
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(
            sent,
            string(
                abi.encodePacked("Failed to withdraw Unclaimed Ether: ", data)
            )
        );
        emit WithdrawUnclaimed(msg.sender, amount);
    }

    /**
     * Withdraws/Recovers ERC20 Tokens
     * Inputs: ERC20 Contract and the amount to be withdrawn
     * Through contract there is no way to know how much tokes
     * were sent to this contract by mistake.
     * We have to implement this through typescript.
     */
    function recoverERC20(IERC20 contractAddress, uint256 amount)
        external
        onlyOwner
    {
        bool success = contractAddress.transfer(msg.sender, amount);
        require(success, "Failed to withdraw ERC20");
        emit RecoverERC20(msg.sender, amount);
    }

    /**
     * Catches fallback and receive functions in wei.
     * This function updates the balances of those that
     * by mistake have sent ethers to this contract.
     * They can withdraw back using the function: recoverEther.
     */
    function catchFunction(address sender, uint256 amount) private {
        uint256 fromBalance = amountSentInWeiOf[sender];
        amountSentInWeiOf[sender] = fromBalance + amount;
        emit Catch(sender, amount);
    }

    function buyMDSCWithEther() public payable {
        uint256 amount = msg.value;
        require(amount > 0, "No Ether sent.");        

        // Updating the sender's invested Ether balance (in Wei)
        uint256 fromBalance = amountInvestedInWeiOf[msg.sender];
        amountInvestedInWeiOf[msg.sender] = fromBalance + amount;

        // Exchange Ether to MDST (Price of Half-Shekel of Silver)
        // We have 18 decimal places from ether to wei
        // and 8 decimal places for ethUsdPrice
        // which gives us 26 decimal places in total,
        // as we want 2 decimal places for cents,
        // then we need to divide by 10**24
        uint256 amountInUsdWithCents = (amount * ethUsdPrice) / 10**24;

        // xagUsdPrice has 8 decimal places
        // and the Const has 9 decimal places
        // which gives us 17 decimal places in total,
        // as we want 2 decimal places for cents,
        // then we need to divide by 10**15
        // Then we update the state variable.
        MDSCPriceWithCentsInUSD = (xagUsdPrice * misc.halfShekelConst) / 10**15;

        // Converting the amount sent into MDSC's
        uint256 amountOfMdscs = amountInUsdWithCents / MDSCPriceWithCentsInUSD;

        // Setting the reserve with the remainder of the above division in USD with cents.
        reserveInUsdFromRemaindersWithCents +=
            amountInUsdWithCents %
            MDSCPriceWithCentsInUSD;

        mint(msg.sender, amountOfMdscs * 10**decimals());
    }

    function sellMDSCforEther(uint256 amountOfMDSC) public payable {
        // Getting how much the user has invested in wei (18 decimals)
        uint256 fromBalanceInWei = amountInvestedInWeiOf[msg.sender];
        require(fromBalanceInWei > 0, "You have insuficient funds in Ethers available for this transaction.");

        // Getting how much the user has in MDSC's (2 decimals)
        uint256 fromMDSCBalance = balanceOf(msg.sender);
        require(amountOfMDSC <= fromMDSCBalance, "Insuficient funds in MDSC's available for this transaction.");

        // Calculate how much the balance in wei represents in MDSC
        uint256 amountOfWeiInUsdWithCents = (fromBalanceInWei * ethUsdPrice) / 10**24;
        // Updating the price of MDSC
        MDSCPriceWithCentsInUSD = (xagUsdPrice * misc.halfShekelConst) / 10**15;
        uint256 amountOfPossibleMDSCsToExchange = amountOfWeiInUsdWithCents / MDSCPriceWithCentsInUSD;        

        if (amountOfMDSC > amountOfPossibleMDSCsToExchange) {
            // Burn only the amount of possible MDSC's to exchange    
            burn(msg.sender, amountOfPossibleMDSCsToExchange);
            amountInvestedInWeiOf[msg.sender] = 0;            
            // Send Ether
            (bool sent, bytes memory data) = msg.sender.call{value: fromBalanceInWei}("");
            require(sent, string(abi.encodePacked("Failed to withdraw Ether: ", data)));
        } else {            
            // Exchanging MDSC's (2 decimals) into USD (2 decimals)
            uint256 amountInUsdWithCents = (amountOfMDSC * MDSCPriceWithCentsInUSD) / 10**2;
            // Exchanging USD (2 decimals) using ethusdprice (8 decimals) into ETH (18 decimals)
            uint256 amountInWei = (amountInUsdWithCents * 10**25) / ethUsdPrice;            
            // Burn the amount of MDSC's the user wants to exchange 
            burn(msg.sender, amountOfMDSC);
            amountInvestedInWeiOf[msg.sender] -= amountInWei;
            (bool sent, bytes memory data) = msg.sender.call{value: amountInWei}("");
            require(sent, string(abi.encodePacked("Failed to withdraw Ether: ", data)));
        }
    }


    function buyMDSCWithUSDT() public {}    
    function sellMDSCforUSDT() public {}
}
