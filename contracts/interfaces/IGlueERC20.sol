// SPDX-License-Identifier: BUSL-1.1
// https://github.com/glue-finance/glue/blob/main/LICENCE.txt
/**

 ██████╗ ██╗     ██╗   ██╗███████╗                                               
██╔════╝ ██║     ██║   ██║██╔════╝                                               
██║  ███╗██║     ██║   ██║█████╗                                                 
██║   ██║██║     ██║   ██║██╔══╝                                                 
╚██████╔╝███████╗╚██████╔╝███████╗                                               
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝      
██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗           
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝           
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗             
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝             
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗           
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝                                                    
███████╗ ██████╗ ██████╗     ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗███████╗
██╔════╝██╔═══██╗██╔══██╗    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║██╔════╝
█████╗  ██║   ██║██████╔╝       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║███████╗
██╔══╝  ██║   ██║██╔══██╗       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║╚════██║
██║     ╚██████╔╝██║  ██║       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║███████║
╚═╝      ╚═════╝ ╚═╝  ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝

 */
pragma solidity ^0.8.28;

/**

 ██████╗ ██╗     ██╗   ██╗███████╗  
██╔════╝ ██║     ██║   ██║██╔════╝  
██║  ███╗██║     ██║   ██║█████╗    
██║   ██║██║     ██║   ██║██╔══╝    
╚██████╔╝███████╗╚██████╔╝███████╗  
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝  
███████╗████████╗██╗ ██████╗██╗  ██╗
██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝
███████╗   ██║   ██║██║     █████╔╝ 
╚════██║   ██║   ██║██║     ██╔═██╗ 
███████║   ██║   ██║╚██████╗██║  ██╗
╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝

* @title IGlueStickERC20
* @author @BasedToschi
* @notice Factory contract that creates and manages individual glue instances for ERC20 tokens
* @dev This contract acts as the primary entry point to the Glue protocol. It deploys minimal proxies
* using the Clones library to create individual GlueERC20 instances for each token, maintaining a
* registry of all glued tokens and their corresponding glue addresses. It also provides batch operations
* and cross-glue flash loan functionality.
*/
interface IGlueStickERC20 {

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 
*/

    /**
    * @dev Struct for managing flash loan data across multiple glue contracts
    * @notice Encapsulates all data required for multi-glue flash loan operations
    */
    struct LoanData {
        uint256 count;              /// @notice Number of glue contracts participating in the loan
        uint256[] toBorrow;         /// @notice Amount to borrow from each glue contract
        uint256[] expectedAmounts;  /// @notice Expected repayment amount for each loan (including fees)
        uint256[] expectedBalances; /// @notice Expected final balance in each glue after repayment
    }

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▖ ▗▖▗▖  ▗▖ ▗▄▄▖▗▄▄▄▖▗▄▄▄▖ ▗▄▖ ▗▖  ▗▖ ▗▄▄▖
▐▌   ▐▌ ▐▌▐▛▚▖▐▌▐▌     █    █  ▐▌ ▐▌▐▛▚▖▐▌▐▌   
▐▛▀▀▘▐▌ ▐▌▐▌ ▝▜▌▐▌     █    █  ▐▌ ▐▌▐▌ ▝▜▌ ▝▀▚▖
▐▌   ▝▚▄▞▘▐▌  ▐▌▝▚▄▄▖  █  ▗▄█▄▖▝▚▄▞▘▐▌  ▐▌▗▄▄▞▘
01000110 01110101 01101110 01100011 01110100 
01101001 01101111 01101110 01110011                               
*/
    
    /**
    * @notice Creates a new GlueERC20 contract for the specified ERC20 token
    * @dev Performs validation checks, creates a deterministic clone of the implementation contract,
    * initializes it with the token address, and registers it in the protocol's mappings.
    * The created glue instance becomes the collateral vault for the sticky token.
    * 
    * @param asset The address of the ERC20 token to be glued
    * @return glueAddress The address of the newly created glue instance
    *
    * Use cases:
    * - Adding asset backing capability to existing tokens
    * - Creating on-chain collateralization mechanisms for tokens
    * - Establishing new tokenomics models with withdrawal mechanisms
    * - Supporting floor price protection for collections through backing
    */
    function applyTheGlue(address asset) external returns (address glueAddress);

    /**
    * @notice Processes ungluing operations for multiple sticky tokens in a single transaction
    * @dev Efficiently batches unglue operations across multiple sticky tokens, managing the
    * transfer of tokens from the caller, approval to glue contracts, and execution of unglue
    * operations. Supports both single and multiple recipient configurations.
    * 
    * @param stickyAssets Array of sticky token addresses to unglue from
    * @param stickyAmounts Array of amounts to unglue for each sticky token
    * @param collaterals Array of collateral addresses to withdraw (common across all unglue operations)
    * @param recipients Array of recipient addresses to receive the unglued collateral
    *
    * Use cases:
    * - Unglue collaterals across multiple sticky tokens
    * - Efficient withdrawal of collaterals from multiple sticky tokens
    * - Consolidated position exits for complex strategies
    * - Multi-token redemption in a single transaction
    */
    function batchUnglue(address[] calldata stickyAssets,uint256[] calldata stickyAmounts,address[] calldata collaterals,address[] calldata recipients) external;
    
    /**
    * @notice Executes flash loans from multiple glue contracts
    * @dev Coordinates complex flash loan operations from multiple sources, calculates 
    * loan amounts, executes the loans, calls the receiver's callback, and verifies
    * that all loans are properly repaid. Implements comprehensive security checks.
    * 
    * @param glues Array of glue contract addresses to borrow from
    * @param collateral Address of the token to borrow (address(0) for ETH)
    * @param loanAmount Total amount of tokens to borrow across all glues
    * @param receiver Address of the contract implementing IGluedLoanReceiver
    * @param params Arbitrary data to be passed to the receiver
    *
    * Use cases:
    * - Flash Loans across multiple glues
    * - Capital-efficient arbitrage across DEXes
    * - Liquidation operations in lending protocols
    * - Complex cross-protocol interactions requiring upfront capital
    * - Temporary liquidity for atomic multi-step operations
    * - Collateral swaps without requiring pre-owned capital
    */
    function gluedLoan(address[] calldata glues, address collateral, uint256 loanAmount, address receiver, bytes calldata params) external;

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▖ ▗▄▄▄▖ ▗▄▖ ▗▄▄▄ 
▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌  █
▐▛▀▚▖▐▛▀▀▘▐▛▀▜▌▐▌  █
▐▌ ▐▌▐▙▄▄▖▐▌ ▐▌▐▙▄▄▀
01010010 01100101 
01100001 01100100                         
*/
    
    /**
    * @notice Retrieves expected collateral amounts from batch ungluing operations
    * @dev View function to calculate expected collateral returns for multiple sticky tokens.
    * This function is critical for front-end applications and smart contract integrations to
    * estimate expected returns before executing batch unglue operations.
    * 
    * @param stickyAssets Array of sticky token addresses
    * @param stickyAmounts Array of sticky token amounts to simulate ungluing
    * @param collaterals Array of collateral addresses to check
    * @return collateralAmounts 2D array of corresponding collateral amounts [glueIndex][collateralIndex]
    *
    * Use cases:
    * - Pre-transaction estimation for front-end applications
    * - Strategy optimization based on expected returns
    * - User interface displays showing potential redemption values
    */
    function getBatchCollaterals(address[] calldata stickyAssets, uint256[] calldata stickyAmounts, address[] calldata collaterals) external view returns (uint256[][] memory collateralAmounts);

    /**
    * @notice Validates if a token can be glued by checking ERC20 compliance
    * @dev Performs static calls to ensure the token implements core ERC20 functionality.
    * Token validation is critical for ensuring only compatible tokens can be glued,
    * preventing issues with non-standard tokens.
    * 
    * @param asset Address of the asset to validate
    * @return isValid Boolean indicating whether the token passes validation checks
    *
    * Use cases:
    * - Pre-glue verification to prevent incompatible token issues
    * - Protocol security to maintain compatibility standards
    * - Front-end validation before attempting glue operations
    */
    function checkAsset(address asset) external view returns (bool isValid);
    
    /**
    * @notice Deterministically predicts the address of a glue contract before creation
    * @dev Uses the Clones library to calculate the exact address where a glue contract 
    * will be deployed. This enables advanced off-chain calculations and integration patterns
    * without requiring the glue to be created first.
    * 
    * @param asset Address of the token to compute the glue address for
    * @return predictedGlueAddress The predicted address where the glue contract would be deployed
    *
    * Use cases:
    * - Complex integrations requiring pre-knowledge of glue addresses
    * - Front-end preparation before actual glue deployment
    * - Cross-contract interactions that reference glue addresses
    * - Security verification of expected deployment addresses
    */
    function computeGlueAddress(address asset) external view returns (address predictedGlueAddress);
    
    /**
    * @notice Checks if a token has been glued and returns its glue address
    * @dev Utility function for external contracts and front-ends to verify token status
    * in the Glue protocol and retrieve the associated glue address if it exists.
    * 
    * @param asset Address of the token to check
    * @return isSticky Indicates whether the token is sticky (has been glued)
    * @return glueAddress The glue address for the token if it's sticky, otherwise address(0)
    *
    * Use cases:
    * - UI elements showing token glue status
    * - Protocol integrations needing to verify glue existence
    * - Smart contracts checking if a token can be unglued
    * - External protocols building on top of the Glue protocol
    */
    function isStickyAsset(address asset) external view returns (bool isSticky, address glueAddress);
    
    /**
    * @notice Retrieves the balances of multiple collaterals across multiple glues
    * @dev Returns a 2D array where each row represents a glue and each column represents a collateral
    *
    * @param glues The addresses of the glues to check
    * @param collaterals The addresses of the collaterals to check for each glue
    * @return balances a 2D array of balances [glueIndex][collateralIndex]
    *
    * Use cases:
    * - Batch querying collateral positions across multiple glues
    * - Dashboard displays showing complete portfolio positions
    * - Cross-glue analytics and reporting
    */
    function getGluesBalances(address[] calldata glues, address[] calldata collaterals) external view returns (uint256[][] memory balances);

    /**
    * @notice Retrieves the glue address for a given token
    * @dev Returns the glue address for the given token
    *
    * @param asset The address of the token to get the glue address for
    * @return glueAddress The glue address for the given token, if it exists, otherwise address(0)
    *
    * Use cases:
    * - Retrieving the glue address for a given token
    */
    function getGlueAddress(address asset) external view returns (address glueAddress);
    
    /**
    * @notice Retrieves a glue address by its index in the registry
    * @dev Returns the address of a deployed glue at the specified index
    * This provides indexed access to the array of all deployed glues
    * 
    * @param index The index in the allGlues array to query
    * @return glueAddress The address of the glue at the specified index
    *
    * Use cases:
    * - Enumeration of all deployed glues in the protocol
    * - Accessing specific glues by index for reporting or integration
    * - Batch operations on sequential glue addresses
    */
    function getGlueAtIndex(uint256 index) external view returns (address glueAddress);
    
    /**
    * @notice Returns the total number of deployed glues.
    * @return existingGlues The length of the allGlues array.
    *
    * Use cases:
    * - Informational queries about the total number of deployed glues
    */
    function allGluesLength() external view returns (uint256 existingGlues);

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▄▄▖ ▗▄▄▖  ▗▄▖ ▗▄▄▖  ▗▄▄▖
▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌   
▐▛▀▀▘▐▛▀▚▖▐▛▀▚▖▐▌ ▐▌▐▛▀▚▖ ▝▀▚▖
▐▙▄▄▖▐▌ ▐▌▐▌ ▐▌▝▚▄▞▘▐▌ ▐▌▗▄▄▞▘
01100101 01110010 01110010 
01101111 01110010 01110011
*/
    
    /**
    * @dev Error thrown when an invalid asset address is provided
    * @param asset The address of the invalid asset
    */
    error InvalidAsset(address asset);
    
    /**
    * @dev Error thrown when attempting to glue a token that's already glued
    * @param asset The address of the duplicate token
    */
    error DuplicateGlue(address asset);
    
    /**
    * @dev Error thrown when an invalid address (typically zero address) is provided
    */
    error InvalidAddress();
    
    /**
    * @dev Error thrown when function inputs are invalid or inconsistent
    */
    error InvalidInputs();
    
    /**
    * @dev Error thrown when a glue contract has insufficient balance
    * @param glue The address of the glue contract
    * @param balance The actual balance found
    * @param collateral The collateral being checked
    */
    error InvalidGlueBalance(address glue, uint256 balance, address collateral);
    
    /**
    * @dev Error thrown when there is insufficient liquidity for a flash loan
    * @param collected The amount of liquidity that was collected
    * @param loanAmount The amount of liquidity that was required
    */
    error InsufficientLiquidity(uint256 collected, uint256 loanAmount);
    
    /**
    * @dev Error thrown when a flash loan operation fails
    */
    error FlashLoanFailed();
    
    /**
    * @dev Error thrown when a flash loan repayment fails
    * @param glue The glue contract that failed to receive repayment
    */
    error RepaymentFailed(address glue);
    
    /**
    * @dev Error thrown when the deployment of a glue contract fails
    */
    error FailedToDeployGlue();

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▄▄▖
▐▌   ▐▌  ▐▌▐▌   ▐▛▚▖▐▌  █ ▐▌   
▐▛▀▀▘▐▌  ▐▌▐▛▀▀▘▐▌ ▝▜▌  █  ▝▀▚▖
▐▙▄▄▖ ▝▚▞▘ ▐▙▄▄▖▐▌  ▐▌  █ ▗▄▄▞▘
01000101 01010110 01000101 
01001110 01010100 01010011
*/
    
    /**
    * @notice Emitted when a new token is infused with glue and became sticky
    * @param asset The address of the token that was infused
    * @param glueAddress The address of the created glue contract
    * @param glueIndex The index of the glue in the allGlues array
    */
    event GlueAdded(address indexed asset, address glueAddress, uint256 glueIndex);
    
    /**
    * @notice Emitted when a batch unglue operation is executed
    * @param stickyAssets Array of tokens that were unglued
    * @param amounts Array of amounts that were processed for each token
    * @param collaterals Array of collateral addresses that were withdrawn
    * @param recipients Array of addresses that received the assets
    */
    event BatchUnglueExecuted(address[] stickyAssets,uint256[] amounts,address[] collaterals,address[] recipients);
}

/**

████████╗██╗  ██╗███████╗         
╚══██╔══╝██║  ██║██╔════╝         
   ██║   ███████║█████╗           
   ██║   ██╔══██║██╔══╝           
   ██║   ██║  ██║███████╗         
   ╚═╝   ╚═╝  ╚═╝╚══════╝         
 ██████╗ ██╗     ██╗   ██╗███████╗
██╔════╝ ██║     ██║   ██║██╔════╝
██║  ███╗██║     ██║   ██║█████╗  
██║   ██║██║     ██║   ██║██╔══╝  
╚██████╔╝███████╗╚██████╔╝███████╗
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝

* @title IGlueERC20
* @author @BasedToschi
* @notice Interface for individual glue contract instances managing ERC20 token collateralization
* @dev This interface defines the API for GlueERC20 contracts that are created by the factory.
* These contracts manage collateral for tokens, process ungluing operations based on
* proportional token amount vs. total supply, and provide flash loan functionality.
*/
interface IGlueERC20 {

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 
*/
    
    /**
    * @notice Enum representing hook detection status
    * @dev Used to track if the token implements and supports hooks
    *
    * Use case: Checking if the token implements native Sticky Asset Standard with activated Hooks
    */
    enum BIO {UNCHECKED,NO_HOOK,HOOK}
        
    /**
    * @notice Initializes a newly deployed glue clone
    * @dev Called by the factory when creating a new glue instance through cloning
    * Sets up the core state variables and establishes the relationship between
    * this glue instance and its associated sticky token
    * 
    * @param asset Address of the ERC20 token to be linked with this glue
    *
    * Use cases:
    * - Creating a new glue address for a token (now Sticky Token) in which attach collateral
    * - Establishing the token-glue relationship in the protocol
    */
    function initialize(address asset) external;
    
/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▖ ▗▖▗▖  ▗▖ ▗▄▄▖▗▄▄▄▖▗▄▄▄▖ ▗▄▖ ▗▖  ▗▖ ▗▄▄▖
▐▌   ▐▌ ▐▌▐▛▚▖▐▌▐▌     █    █  ▐▌ ▐▌▐▛▚▖▐▌▐▌   
▐▛▀▀▘▐▌ ▐▌▐▌ ▝▜▌▐▌     █    █  ▐▌ ▐▌▐▌ ▝▜▌ ▝▀▚▖
▐▌   ▝▚▄▞▘▐▌  ▐▌▝▚▄▄▖  █  ▗▄█▄▖▝▚▄▞▘▐▌  ▐▌▗▄▄▞▘
01000110 01110101 01101110 01100011 01110100 
01101001 01101111 01101110 01110011                               
*/

    /**
    * @notice Processes the ungluing of tokens to withdraw collateral
    * @dev Core function for token burning and proportional collateral withdrawal
    * @param collaterals Array of collateral token addresses to withdraw
    * @param amount Amount of tokens to process
    * @param recipient Address to receive the withdrawn collateral
    * @return supplyDelta Proportion of total supply being burned (in PRECISION units)
    * @return realAmount Actual amount of tokens processed (after transfer)
    * @return beforeTotalSupply Token supply before the operation
    * @return afterTotalSupply Token supply after the operation
    * 
    * Use case: Redeeming collateral by burning sticky tokens
    */
    function unglue(address[] calldata collaterals, uint256 amount, address recipient) external returns (uint256 supplyDelta, uint256 realAmount, uint256 beforeTotalSupply, uint256 afterTotalSupply);
    
    /**
    * @notice Initiates a flash loan.
    * @dev This function is used to initiate a flash loan.
    *
    * @param collateral The address of the collateral token.
    * @param amount The amount of tokens to flash loan.
    * @param receiver The address of the receiver.
    * @param params The parameters for the flash loan.
    * @return success boolean indicating success
    *
    * Use cases:
    * - Initiating a simplified Glued loan from this Glue.
    * - Initiating a flash loan with simpler integration.
    */
    function flashLoan(address collateral, uint256 amount, address receiver, bytes calldata params) external returns (bool success);
    
    /**
    * @notice Initiates a minimal flash loan.
    * @dev This function is used for the Glue Stick to handle collateral in a Glued Loan.
    * @dev Only the Glue Stick can call this function.
    *
    * @param receiver The address of the receiver.
    * @param collateral The address of the token to flash loan.
    * @param amount The amount of tokens to flash loan.
    * @return loanSent boolean indicating success
    *
    * Use cases:
    * - Handle collateral in a Glued Loan.
    */
    function loanHandler(address receiver, address collateral, uint256 amount) external returns (bool loanSent);

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▖ ▗▄▄▄▖ ▗▄▖ ▗▄▄▄ 
▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌  █
▐▛▀▚▖▐▛▀▀▘▐▛▀▜▌▐▌  █
▐▌ ▐▌▐▙▄▄▖▐▌ ▐▌▐▙▄▄▀
01010010 01100101 
01100001 01100100                         
*/
    
    /**
    * @notice Calculates the supply delta based on the sticky token amount and total supply.
    * @dev This function is used to calculate the supply delta based on the sticky token amount and total supply.
    *
    * @param stickyAmount The amount of sticky tokens.
    * @return supplyDelta The calculated supply delta.
    *
    * Use cases:
    * - Calculating the supply delta based on the sticky token amount.
    *
    * @dev The Supply Delta calculated here can loose precision if the Sticky Token implement a Tax on tranfers, 
    * for these tokens is better to emulate the unglue function. 
    */
    function getSupplyDelta(uint256 stickyAmount) external view returns (uint256 supplyDelta);
    
    /**
    * @notice Retrieves the adjusted total supply of the sticky token.
    * @dev This function is used to get the adjusted total supply of the sticky token.
    *
    * @return adjustedTotalSupply The adjusted and actual total supply of the sticky token.
    *
    * Use cases:
    * - Retrieving the adjusted total supply of the sticky token.
    */
    function getAdjustedTotalSupply() external view returns (uint256 adjustedTotalSupply);
    
    /**
    * @notice Retrieves the protocol fee percentage.
    * @dev This function is used to get the protocol fee percentage.
    *
    * @return protocolFee The protocol fee as a fixed-point number with 18 decimal places.
    *
    * Use cases:
    * - Retrieving the protocol fee percentage fixed to 1e15 = 0.1% | 1e18 = 100%.
    */
    function getProtocolFee() external pure returns (uint256);
    
    /**
    * @notice Retrieves the flash loan fee percentage.
    * @dev This function is used to get the flash loan fee percentage.
    * @dev The flash loan fee is fully paid to the Glue
    *
    * @return flashLoanFee The flash loan fee as a fixed-point number with 18 decimal places.
    *
    * Use cases:
    * - Retrieving the flash loan fee percentage fixed to 1e14 = 0.01% | 1e18 = 100%.
    */
    function getFlashLoanFee() external pure returns (uint256 flashLoanFee);
    
    /**
    * @notice Retrieves the flash loan fee for a given amount.
    * @dev This function is used to get the flash loan fee for a given amount.
    *
    * @param amount The amount to calculate the flash loan fee for.
    * @return fee The flash loan fee applied to a given amount.
    *
    * Use cases:
    * - Retrieving the flash loan fee applied to a given amount.
    */
    function getFlashLoanFeeCalculated(uint256 amount) external pure returns (uint256 fee);
    
    /**
    * @notice Returns the total hook size for a specific collateral
    * @dev Used for hook impact calculations during ungluing
    * @param collateral The address of the collateral token
    * @param collateralAmount The amount of collateral being processed
    * @param stickyAmount The amount of sticky tokens being unglued
    * @return hookSize The combined hook impact in PRECISION units
    * 
    * Use case: Accurate estimation of hook effects on collateral withdrawal
    */
    function getTotalHookSize(address collateral, uint256 collateralAmount, uint256 stickyAmount) external view returns (uint256 hookSize);
    
    /**
    * @notice Calculates the amount of collateral tokens that can be unglued for a given sticky token amount.
    * @dev This function is used to calculate the amount of collateral tokens that can be unglued for a given sticky token amount.
    *
    * @param stickyAmount The amount of sticky tokens to unglue.
    * @param collaterals An array of addresses representing the collateral tokens to unglue.
    * @return amounts An array containing the corresponding amounts that can be unglued.
    * @dev This function accounts for the protocol fee in its calculations.
    *
    * Use cases:
    * - Calculating the amount of collateral tokens that can be unglued for a given sticky token amount.
    * @dev This function can loose precision if the Sticky Token implement a Tax on tranfers.
    */
    function collateralByAmount(uint256 stickyAmount, address[] calldata collaterals) external view returns (uint256[] memory amounts);
    
    /**
    * @notice Retrieves the balance of an array of specified collateral tokens for the glue contract.
    * @dev This function is used to get the balance of an array of specified collateral tokens for the glue contract.
    *
    * @param collaterals An array of addresses representing the collateral tokens.
    * @return balances An array containing the corresponding balances.
    *
    * Use cases:
    * - Retrieving the balance of an array of specified collateral tokens for the glue contract.
    */
    function getBalances(address[] calldata collaterals) external view returns (uint256[] memory balances);
    
    /**
    * @notice Retrieves the balance of the sticky asset for the glue contract.
    * @dev This function is used to get the balance of the sticky token for the glue contract.
    *
    * @return stickyAmount The balance of the sticky token.
    *
    * Use cases:
    * - Retrieving the balance of the sticky token for the glue contract.
    */
    function getStickySupplyStored() external view returns (uint256 stickyAmount);

    /**
    * @notice Retrieves the settings contract address.
    * @dev This function is used to get the settings contract address.
    *
    * @return settings The address of the settings contract.
    *
    * Use cases:
    * - Retrieving the settings contract address.
    */
    function getSettings() external pure returns (address settings);

    /**
    * @notice Retrieves the address of the GlueStick factory contract.
    * @dev This function is used to get the address of the GlueStick factory contract.
    *
    * @return glueStick The address of the GlueStick factory contract.
    *
    * Use cases:
    * - Retrieving the address of the GlueStick factory contract.
    */
    function getGlueStick() external view returns (address glueStick);

    /**
    * @notice Retrieves the address of the sticky token.
    * @dev This function is used to get the address of the sticky token.
    *
    * @return stickyAsset The address of the sticky token.
    *
    * Use cases:
    * - Retrieving the address of the sticky token.
    */
    function getStickyAsset() external view returns (address stickyAsset);

    /**
    * @notice Retrieves if the glue is expanded with active Hooks.
    * @dev This function is used to get if the glue is expanded with active Hooks:
    * - BIO.HOOK: The glue is expanded with active Hooks.
    * - BIO.NO_HOOK: The glue is not expanded with active Hooks.
    * - BIO.UNCHECKED: The glue didn't have learned yet (before the first unglue interaction).
    *
    * @return hooksStatus The bio of the hooks status.
    *
    * Use cases:
    * - Knowing if the glue is expanded with active Hooks for external interactions.
    */
    function isExpanded() external view returns (BIO hooksStatus);
    
    /**
    * @notice Retrieves if the Sticky Asset is natively not burnable, if it follow the ERC20 standard and 
    * if the sticky token is permanently stored in the contract.
    * @dev This function is used to get if the Sticky Asset is natively not burnable, 
    * if it follow the ERC20 standard and if the sticky token is permanently stored in the contract.
    *
    * @return noNativeBurn A boolean representing if the sticky asset is natively not burnable.
    * @return nonStandard A boolean representing if the sticky asset is standard and address(0) is not counted in the total supply.
    * @return stickySupplyGlued A boolean representing if the sticky token is permanently stored in the contract.
    *
    * Use cases:
    * - Knowing if the Sticky Asset is natively not burnable, follow the ERC20 standard if the sticky token is permanently stored in the contract.
    */
    function getSelfLearning() external view returns (bool noNativeBurn, bool nonStandard, bool stickySupplyGlued);

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▄▄▖ ▗▄▄▖  ▗▄▖ ▗▄▄▖  ▗▄▄▖
▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌   
▐▛▀▀▘▐▛▀▚▖▐▛▀▚▖▐▌ ▐▌▐▛▀▚▖ ▝▀▚▖
▐▙▄▄▖▐▌ ▐▌▐▌ ▐▌▝▚▄▞▘▐▌ ▐▌▗▄▄▞▘
01100101 01110010 01110010 
01101111 01110010 01110011
*/
    
    /**
    * @dev Error thrown when an invalid GlueStick address is provided
    */
    error InvalidGlueStickAddress();

    /**
    * @dev Error thrown when an unauthorized caller attempts an operation
    */
    error Unauthorized();

    /**
    * @dev Error thrown when a zero amount is provided where a non-zero amount is required
    */
    error ZeroAmount();
    
    /**
    * @dev Error thrown when an invalid asset address is provided
    * @param asset The address of the invalid asset
    */
    error InvalidAsset(address asset);
    
    /**
    * @dev Error thrown when no collateral is selected for ungluing
    */
    error NoCollateralSelected();
    
    /**
    * @dev Error thrown when no tokens are transferred during an operation
    */
    error NoAssetsTransferred();
    
    /**
    * @dev Error thrown when a asset transfer fails
    * @param asset The asset that failed to transfer
    * @param recipient The intended recipient
    */
    error TransferFailed(address asset, address recipient);

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▄▄▖
▐▌   ▐▌  ▐▌▐▌   ▐▛▚▖▐▌  █ ▐▌   
▐▛▀▀▘▐▌  ▐▌▐▛▀▀▘▐▌ ▝▜▌  █  ▝▀▚▖
▐▙▄▄▖ ▝▚▞▘ ▐▙▄▄▖▐▌  ▐▌  █ ▗▄▄▞▘
01000101 01010110 01000101 
01001110 01010100 01010011
*/
    
    /**
    * @notice Emitted when tokens are unglued and collateral is withdrawn
    * @param recipient The address receiving the withdrawn collateral
    * @param realAmount The amount of tokens that were processed
    * @param beforeTotalSupply The total supply before the operation
    * @param afterTotalSupply The total supply after the operation
    * @param supplyDelta The supply delta
    */
    event unglued(address indexed recipient, uint256 realAmount, uint256 beforeTotalSupply, uint256 afterTotalSupply, uint256 supplyDelta);
    
    /**
    * @notice Emitted when a flash loan is executed
    * @param collateral The address of the borrowed asset
    * @param amount The amount that was borrowed
    * @param receiver The address that received the loan
    */
    event GlueLoan(address indexed collateral, uint256 amount, address receiver);
}