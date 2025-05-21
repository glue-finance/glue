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
███████╗ ██████╗ ██████╗     ███╗   ██╗███████╗████████╗███████╗      
██╔════╝██╔═══██╗██╔══██╗    ████╗  ██║██╔════╝╚══██╔══╝██╔════╝      
█████╗  ██║   ██║██████╔╝    ██╔██╗ ██║█████╗     ██║   ███████╗      
██╔══╝  ██║   ██║██╔══██╗    ██║╚██╗██║██╔══╝     ██║   ╚════██║      
██║     ╚██████╔╝██║  ██║    ██║ ╚████║██║        ██║   ███████║      
╚═╝      ╚═════╝ ╚═╝  ╚═╝    ╚═╝  ╚═══╝╚═╝        ╚═╝   ╚══════╝      

*/


pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**

██████╗ ██╗   ██╗██████╗ ███╗   ██╗ █████╗ ██████╗ ██╗     ███████╗
██╔══██╗██║   ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██║     ██╔════╝
██████╔╝██║   ██║██████╔╝██╔██╗ ██║███████║██████╔╝██║     █████╗  
██╔══██╗██║   ██║██╔══██╗██║╚██╗██║██╔══██║██╔══██╗██║     ██╔══╝  
██████╔╝╚██████╔╝██║  ██║██║ ╚████║██║  ██║██████╔╝███████╗███████╗
╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
███╗   ██╗███████╗████████╗███████╗                                
████╗  ██║██╔════╝╚══██╔══╝██╔════╝                                
██╔██╗ ██║█████╗     ██║   ███████╗                                
██║╚██╗██║██╔══╝     ██║   ╚════██║                                
██║ ╚████║██║        ██║   ███████║                                
╚═╝  ╚═══╝╚═╝        ╚═╝   ╚══════╝                                

* @title IERC721Burnable
* @author @BasedToschi
* @notice Interface for ERC721 tokens that support burning functionality
* @dev Extends the standard ERC721 interface with a burn function to destroy tokens
*/
interface IERC721Burnable is IERC721 {
    /**
    * @notice Burns (destroys) the token with the given ID
    * @dev The caller must own the token or be an approved operator
    * @param tokenId The ID of the token to burn
    */
    function burn(uint256 tokenId) external;
}

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

* @title IGlueStickERC721
* @author @BasedToschi
* @notice Interface defining the factory contract API for creating and managing ERC721 NFT collection glue instances
* @dev This interface establishes the contract API for the GlueStickERC721 factory,
* which handles creation of glue contracts for NFT collections, batch operations,
* and cross-glue flash loans in the NFT branch of the Glue Protocol
*/
interface IGlueStickERC721 {
    
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
    * @notice Creates a new GlueERC721 contract for a specified NFT collection
    * @dev Validates the NFT collection for compatibility, creates a deterministic clone
    * of the implementation contract, initializes it with the collection address, and
    * registers it in the protocol registry. The created glue instance becomes the
    * collateral vault for the NFT collection.
    * 
    * @param asset The address of the ERC721 collection to be glued
    * @return glueAddress The address of the newly created glue instance
    *
    * Use cases:
    * - Adding asset backing capabilities to existing NFT collections
    * - Creating collateralization mechanisms for NFTs
    * - Establishing new NFT economic models with withdrawal mechanisms
    * - Supporting floor price protection for collections through backing
    */
    function applyTheGlue(address asset) external returns (address glueAddress);

    /**
    * @notice Processes ungluing operations for multiple NFT collections in a single transaction
    * @dev Efficiently batches unglue operations across multiple NFT collections, managing the
    * transfer of NFTs from caller to glue contracts, and execution of unglue operations.
    * Supports both single and multiple recipient configurations.
    * 
    * @param stickyAssets Array of NFT collection addresses to unglue from
    * @param tokenIds Two-dimensional array of token IDs to unglue for each collection
    * @param collaterals Array of collateral addresses to withdraw (common across all unglue operations)
    * @param recipients Array of recipient addresses to receive the unglued collateral
    *
    * Use cases:
    * - Unglue collaterals across multiple sticky NFT collections
    * - Efficient withdrawal of collaterals from multiple sticky NFT collections
    * - Consolidated position exits for complex NFT strategies
    * - Multi-collection redemption in a single transaction
    */
    function batchUnglue(address[] calldata stickyAssets,uint256[][] calldata tokenIds,address[] calldata collaterals,address[] calldata recipients) external;
    
    /**
    * @notice Executes multiple flash loans across multiple glues.
    * @dev This function calculates the loans, executes them, and verifies the repayments.
    *
    * @param glues The addresses of the glues to borrow from.
    * @param collateral The address of the collateral to borrow.
    * @param loanAmount The total amount of collaterals to borrow.
    * @param receiver The address of the receiver.
    * @param params Additional parameters for the receiver.
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
    * @notice Retrieves expected collateral amounts from batch ungluing operations for NFTs
    * @dev View function to calculate expected collateral returns for multiple NFT collections.
    * This is essential for front-end applications and integrations to estimate expected
    * returns before executing batch unglue operations.
    * 
    * @param stickyAssets Array of NFT collection addresses
    * @param stickyAmounts Array of NFT counts to simulate ungluing (number of NFTs, not IDs)
    * @param collaterals Array of collateral addresses to check
    * @return collateralAmounts 2D array of corresponding collateral amounts [glueIndex][collateralIndex]
    *
    * Use cases:
    * - Pre-transaction estimation for front-end applications
    * - Strategy optimization based on expected returns
    * - User interface displays showing potential redemption values
    */
    function getBatchCollaterals(address[] calldata stickyAssets,uint256[] calldata stickyAmounts,address[] calldata collaterals) external view returns (uint256[][] memory collateralAmounts);

    /**
    * @notice Checks if the given ERC721 address has valid totalSupply and no decimals
    * @dev This function performs static calls to check if token is a valid NFT
    * Token validation is critical for ensuring only compatible collections can be glued,
    * preventing issues with non-enumerable NFT collections.
    * 
    * @param asset The address of the ERC721 asset to check
    * @return isValid Indicates whether the token is valid
    *
    * Use cases:
    * - Pre-glue verification to prevent incompatible token issues
    * - Protocol security to maintain compatibility standards
    * - Front-end validation before attempting glue operations
    */
    function checkAsset(address asset) external view returns (bool isValid);
    
    /**
    * @notice Computes the address of the GlueERC721 contract for the given ERC721 address.
    * @dev Uses the Clones library to predict the address of the minimal proxy.
    *
    * @param asset The address of the ERC721 contract.
    * @return predictedGlueAddress The computed address of the GlueERC721 contract.
    *
    * Use cases:
    * - Complex integrations requiring pre-knowledge of glue addresses
    * - Front-end preparation before actual glue deployment
    * - Cross-contract interactions that reference glue addresses
    * - Security verification of expected deployment addresses
    */
    function computeGlueAddress(address asset) external view returns (address predictedGlueAddress);
    
    /**
    * @notice Checks if a given token is sticky and returns its glue address
    * @dev Utility function for external contracts and front-ends to verify token status
    * in the Glue protocol and retrieve the associated glue address if it exists.
    * 
    * @param asset The address of the NFT Collection to check
    * @return isSticky bool Indicates whether the token is sticky.
    * @return glueAddress The glue address for the token if it's sticky, otherwise address(0).
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
    * @dev This function is used to get the balances of multiple collaterals across multiple glues
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
    * @notice Returns the total number of deployed glues.
    * @return existingGlues The length of the allGlues array.
    *
    * Use cases:
    * - Informational queries about the total number of deployed glues
    */
    function allGluesLength() external view returns (uint256 existingGlues);

    /**
    * @notice Retrieves the glue address for a given token
    * @dev Returns the glue address for the given token
    *
    * @param asset The address of the NFT collection to get the glue address for
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
    * @dev Error thrown when attempting to glue a collection that's already glued
    * @param asset The address of the duplicate collection
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
    * @param totalCollected The amount of liquidity that was collected
    * @param loanAmount The amount of liquidity that was required
    */
    error InsufficientLiquidity(uint256 totalCollected, uint256 loanAmount);
    
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
    * @dev Error thrown when no assets are selected for an operation
    */
    error NoAssetsSelected();
    
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
    * @notice Emitted when a new NFT collection is glued
    * @param asset The address of the collection that was glued
    * @param glueAddress The address of the created glue contract
    * @param glueIndex The index of the glue in the allGlues array
    */
    event GlueAdded(address indexed asset, address glueAddress, uint256 glueIndex);
    
    /**
    * @notice Emitted when a batch unglue operation is executed for NFTs
    * @param stickyAssets Array of NFT collections that were unglued
    * @param tokenIds Two-dimensional array of token IDs that were processed
    * @param collaterals Array of collateral addresses that were withdrawn
    * @param recipients Array of addresses that received the assets
    */
    event BatchUnglueExecuted(address[] stickyAssets,uint256[][] tokenIds,address[] collaterals,address[] recipients);
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

* @title IGlueERC721
* @author @BasedToschi
* @notice Interface for individual glue contract instances managing ERC721 NFT collection collateralization
* @dev This interface defines the API for GlueERC721 contracts that are created by the factory.
* These contracts manage collateral for NFT collections, process ungluing operations based on
* proportional NFT count vs. total supply, and provide flash loan functionality.
*/
interface IGlueERC721 {
    

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
    * @dev Used to track if the collection implements and supports hooks
    * @dev UNCHECKED: The collection has not been checked for hooks. The check happens at the first unglue operation.
    * @dev NO_HOOK: The collection does not implement hooks
    * @dev HOOK: The collection implements hooks
    */
    enum BIO {UNCHECKED,NO_HOOK,HOOK}
    
    /**
    * @notice Initializes a newly deployed glue clone for an NFT collection
    * @dev Called by the factory when creating a new glue instance through cloning
    * Sets up the core state variables and establishes the relationship between
    * this glue instance and its associated NFT collection
    * 
    * @param asset Address of the ERC721 collection to be linked with this glue
    *
    * Use cases:
    * - Creating a new glue address for a NFT collection (now Sticky Token) in which attach collateral
    * - Establishing the collection-glue relationship in the protocol
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
    * @notice Core function that processes NFT ungluing operations to release collateral
    * @dev Handles the complete ungluing workflow for NFTs: verifying ownership,
    * managing transfers, calculating proportional collateral amounts, applying fees,
    * executing hook logic if enabled, and distributing collateral to the recipient.
    * 
    * @param collaterals Array of collateral token addresses to withdraw
    * @param tokenIds Array of NFT token IDs to burn for collateral withdrawal
    * @param recipient Address to receive the withdrawn collateral
    * @return supplyDelta Calculated proportion of total NFT supply (in PRECISION units)
    * @return realAmount Number of NFTs processed (after removing duplicates)
    * @return beforeTotalSupply NFT collection supply before the unglue operation
    * @return afterTotalSupply NFT collection supply after the unglue operation
    *
    * Use cases:
    * - Redeeming collateral from the protocol by burning NFTs
    * - Converting sticky NFTs back to their collaterals
    */
    function unglue(address[] calldata collaterals, uint256[] calldata tokenIds, address recipient) external returns (uint256 supplyDelta, uint256 realAmount, uint256 beforeTotalSupply, uint256 afterTotalSupply);
    
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
    * @notice Calculates the supply delta based on the sticky NFT amount and total supply.
    * @dev This function is used to calculate the supply delta based on the sticky NFT amount and total supply.
    *
    * @param stickyAmount The amount of sticky NFTs.
    * @return supplyDelta The calculated supply delta.
    *
    * Use cases:
    * - Calculating the supply delta based on the sticky NFT amount.
    *
    */
    function getSupplyDelta(uint256 stickyAmount) external view returns (uint256 supplyDelta);
    
    /** 
    * @notice Retrieves the adjusted total supply of the Sticky NFT Collection.
    * @dev This function is used to get the adjusted total supply of the Sticky NFT Collection.
    *
    * @return adjustedTotalSupply The adjusted and actual total supply of the Sticky NFT Collection.
    *
    * Use cases:
    * - Retrieving the adjusted total supply of the Sticky NFT Collection.
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
    function getProtocolFee() external pure returns (uint256 protocolFee);
    
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
    * @notice Retrieves the total hook size for a sepecific collateral.
    * @dev This function is used to get the total hook size for a sepecific collateral or sticky token.
    *
    * @param collateral The address of the collateral token.
    * @param collateralAmount The amount of tokens to calculate the hook size for.
    * @return hookSize The total hook size.
    *
    * Use cases:
    * - Retrieving the total hook size for a specific collateral.
    */
    function getTotalHookSize(address collateral, uint256 collateralAmount) external view returns (uint256 hookSize);
    
    /**
    * @notice Calculates the amount of collateral tokens that can be unglued for a given amount of sticky tokens.
    * @dev This function is used to calculate the amount of collateral tokens that can be unglued for a given amount of sticky tokens.
    *
    * @param stickyAmount The amount of sticky tokens to be burned.
    * @param collaterals An array of addresses representing the collateral tokens to unglue.
    * @return amounts An array containing the corresponding amounts that can be unglued.
    * @dev This function accounts for the protocol fee in its calculations.
    *
    * Use cases:
    * - Calculating the amount of collateral tokens that can be unglued for a given amount of sticky tokens.
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
    * @notice Retrieves the balance of the sticky NFTs for the glue contract.
    * @dev This function is used to get the balance of the sticky NFTs for the glue contract.
    *
    * @return stickyAmount The balance of the sticky NFTs.
    *
    * Use cases:
    * - Retrieving the balance of the sticky NFTs for the glue contract.
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
    * @return stickyAsset The address of the sticky NFT collection.
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
    * @notice Retrieves if the Sticky Asset is natively not burnable and 
    * if the sticky token is permanently stored in the contract.
    * @dev This function is used to get if the Sticky Asset is natively not burnable, 
    * and if the sticky token is permanently stored in the contract.
    *
    * @return noNativeBurn A boolean representing if the sticky asset is natively not burnable.
    * @return stickySupplyGlued A boolean representing if the sticky token is permanently stored in the contract.
    *
    * Use cases:
    * - Knowing if the Sticky Asset is natively not burnable and if the sticky token is permanently stored in the contract.
    */
    function getSelfLearning() external view returns (bool noNativeBurn, bool stickySupplyGlued);

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
    * @dev Error thrown when no assets are selected for ungluing
    */
    error NoAssetsSelected();
    
    /**
    * @dev Error thrown when an invalid GlueStick factory address is provided
    */
    error InvalidGlueStickAddress();
    
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
    * @dev Error thrown when the contract fails to process an NFT collection operation
    */
    error FailedToProcessCollection();
    
    /**
    * @dev Error thrown when an unauthorized caller attempts an operation
    */
    error Unauthorized();
    
    /**
    * @dev Error thrown when a zero amount is provided where a non-zero amount is required
    */
    error ZeroAmount();

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
    * @notice Emitted when NFTs are unglued and collateral is withdrawn
    * @param recipient The address receiving the withdrawn collateral
    * @param realAmount The number of NFTs that were processed
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