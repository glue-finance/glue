// SPDX-License-Identifier: BUSL-1.1

/**

███████╗ █████╗ ███╗   ██╗                                            
██╔════╝██╔══██╗████╗  ██║                                            
███████╗███████║██╔██╗ ██║                                            
╚════██║██╔══██║██║╚██╗██║                                            
███████║██║  ██║██║ ╚████║                                            
╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝                                            
██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗  
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝  
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝

 */
pragma solidity ^0.8.28;

/**

 ██████╗ ██╗     ██╗   ██╗███████╗██████╗                             
██╔════╝ ██║     ██║   ██║██╔════╝██╔══██╗                            
██║  ███╗██║     ██║   ██║█████╗  ██║  ██║                            
██║   ██║██║     ██║   ██║██╔══╝  ██║  ██║                            
╚██████╔╝███████╗╚██████╔╝███████╗██████╔╝                            
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝                             
██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗███████╗                            
██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██╔════╝                            
███████║██║   ██║██║   ██║█████╔╝ ███████╗                            
██╔══██║██║   ██║██║   ██║██╔═██╗ ╚════██║                            
██║  ██║╚██████╔╝╚██████╔╝██║  ██╗███████║                            
╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝                            
██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗  
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝  
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝

 * @title IGluedHooks
 * @author BasedToschi
 * @notice Extension interface that defines callback mechanisms for Sticky Assets to interact with the Glue Protocol
 * @dev Provides a standardized set of methods that Sticky Assets must implement to receive and process callbacks
 * during critical operations like collateral ungluing and token burning. This interface enables advanced features
 * like fee collection, rebasing mechanisms, and custom logic execution during protocol interactions.
 */
interface IGluedHooks {
    
    /**
     * @notice Calculates the appropriate hook size for token operations
     * @dev Called by the Glue Protocol to determine what percentage of tokens should be redirected to the token contract
     * during ungluing operations. The return value represents a percentage in PRECISION units (1e18 = 100%)
     *
     * @param asset The address of the token being processed (collateral or sticky token)
     * @param amount The amount of tokens being processed by the hook
     * @return size The hook size as a percentage in PRECISION units (e.g. 1e18 = 100%, 5e17 = 50%)
     *
     * Use case: Implementing dynamic fee models, rebasing mechanisms, or treasury allocations during ungluing
     */
    function hookSize(address asset, uint256 amount) external view returns (uint256 size);
    
    /**
     * @notice Main hook execution function called during ungluing operations
     * @dev This function is invoked after tokens have been transferred to the sticky asset contract
     * and gives the asset an opportunity to execute custom logic with the received tokens
     *
     * @param asset The address of the token transferred to the contract (ETH = address(0))
     * @param amount The precise amount of tokens transferred to the contract
     * @param tokenIds Array of token IDs for ERC721 operations (empty for ERC20 tokens)
     *
     * Use case: Implementing automatic token buybacks, liquidity provision, or reward distribution
     */
    function executeHook(address asset, uint256 amount, uint256[] memory tokenIds) external;

    /**
     * @notice Calculates the total impact of all hooks during ungluing operations
     * @dev Provides an aggregated view of how hooks will affect the token distribution
     * for a specific collateral and amount combination
     *
     * @param collateral The address of the collateral token being unglued
     * @param collateralAmount The amount of collateral token being withdrawn from the glue
     * @param stickyAmount The amount of sticky tokens being burned (for ERC20 only)
     * @return size The combined impact of all hooks as a percentage in PRECISION units
     *
     * Use case: Client-side prediction of expected output amounts accounting for hooks
     */
    function hooksImpact(address collateral, uint256 collateralAmount, uint256 stickyAmount) external view returns (uint256 size);

   /**
     * @notice Global hook enablement flag
     * @dev Constant that indicates whether hook functionality is active for this token
     *
     * @return hook Boolean flag: true if hooks are enabled, false if disabled
     *
     * Use case: Protocol optimizations to skip hook processing entirely for tokens without hooks
     */
    function hasHook() external view returns (bool hook);

} 

/**

███████╗████████╗██╗ ██████╗██╗  ██╗██╗   ██╗     █████╗ ███████╗███████╗███████╗████████╗
██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝╚██╗ ██╔╝    ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝
███████╗   ██║   ██║██║     █████╔╝  ╚████╔╝     ███████║███████╗███████╗█████╗     ██║   
╚════██║   ██║   ██║██║     ██╔═██╗   ╚██╔╝      ██╔══██║╚════██║╚════██║██╔══╝     ██║   
███████║   ██║   ██║╚██████╗██║  ██╗   ██║       ██║  ██║███████║███████║███████╗   ██║   
╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝       ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   
██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗                    
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝                    
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗                      
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝                      
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗                    
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝                    

 * @title IStickyAsset
 * @author Basetoschi
 * @notice Interface for the StickyAsset contract
 * @dev Defines the external functions and events that should be implemented by any StickyAsset
 */
interface IStickyAsset is IGluedHooks {

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
    * @notice Internal helper to execute the unglue call based on token type
    * @dev Used by derived contracts to make the correct unglue call
    *
    * @param collaterals Array of collateral addresses to withdraw
    * @param amount For ERC20: amount of tokens, For ERC721: any number < tokenIds.length
    * @param tokenIds For ERC20: empty array [0], For ERC721: array of token IDs to redeem
    * @param recipient Address to receive the redeemed collateral
    *
    * Use cases:
    * - Unglue directly from the asset contract
    */
    function unglue(address[] calldata collaterals,uint256 amount,uint256[] memory tokenIds,address recipient) external;

    /**
    * @notice Executes a flashLoan from the glue through the Glue factory
    * @dev The receiver must implement IGluedLoanReceiver interface
    *
    * @param collateral Address of the token to borrow (cannot be this token itself)
    * @param amount Amount to borrow
    * @param receiver Address of the receiver implementing IGluedLoanReceiver
    * @param params Additional parameters for the receiver
    * @return success True if the loan operation was successful
    *
    * Use cases:
    * - Flash loan using the glued collaterals directly from the asset contract
    */
    function flashLoan(address collateral,uint256 amount,address receiver,bytes calldata params) external returns (bool success);

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
    function getcollateralByAmount(uint256 stickyAmount, address[] calldata collaterals) external view returns (uint256[] memory amounts);

    /**
    * @notice Retrieves the adjusted total supply of the sticky token.
    * @dev This function is used to get the adjusted total supply of the sticky token.
    *
    * @return adjustedTotalSupply The adjusted and actual total supply of the sticky token.
    *
    * Use cases:
    * - Retrieving the adjusted and actual total supply of the sticky token.
    */
    function getAdjustedTotalSupply() external view returns (uint256 adjustedTotalSupply);

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
    * @notice Retrieves the flash loan fee for a given amount.
    * @dev This function is used to get the flash loan fee for a given amount.
    *
    * @param amount The amount to calculate the flash loan fee for.
    * @return fee The flash loan fee applied to a given amount.
    *
    * Use cases:
    * - Retrieving the flash loan fee applied to a given amount.
    */
    function getFlashLoanFeeCalculated(uint256 amount) external view returns (uint256 fee);

    /**
    * @notice Returns the contract URI as EIP-7572
    * @dev This function is used to get the contract URI as EIP-7572
    *
    * @return uRI The contract URI
    *
    * Use cases:
    * - Retrieving the assets information in a common format as EIP-7572
    */
    function contractURI() external view returns (string memory uRI);


    /**
    * @notice Returns the flag indicating if the token is fungible
    * @dev This function is used to get the flag indicating if the token is fungible
    *
    * @return fungible If true the token is fungible (ERC20) if false the token is non-fungible (ERC721)
    *
    * Use cases:
    * - Retrieving the flag indicating if the token is fungible (ERC20 = true) if false the token is non-fungible (ERC721)
    */
    function isFungible() external view returns (bool fungible);

    /**
    * @notice Returns the address of the glue contract
    * @dev This function is used to get the address of the glue contract
    *
    * @return glue The address of the glue contract
    *
    * Use cases:
    * - Retrieving the address of the glue contract
    */
    function getGlue() external view returns (address glue);

    /**
    * @notice Returns the address of the glue stick contract
    * @dev This function is used to get the address of the glue stick contract
    *
    * @return glueStick The address of the glue stick contract
    *
    * Use cases:
    * - Retrieving the address of the glue stick contract
    */
    function getGlueStick() external view returns (address glueStick);

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
     * @notice Thrown when ERC20/ERC721 approval fails
     * @dev This can occur when trying to approve ERC20/ERC721 tokens for the Glue protocol
     */
    error ApproveFailed();

    /**
     * @notice Thrown when the caller is not the GLUE contract
     * @dev This can occur when trying to call the unglue function from the asset contract
     */
    error OnlyGlue();

    /**
     * @notice Thrown when the transfer operation fails
     * @dev This can occur when trying to transfer ERC20/ERC721 tokens
     */
    error TransferFailed();

    /**
     * @notice Thrown when the token IDs are invalid
     * @dev This can occur when trying to redeem invalid token IDs
     */
    error InvalidTokenIds();

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
     * @notice Emitted when the hook is executed
     * @param asset Address of the asset
     * @param amount Amount of tokens redeemed (for ERC20) or number of tokens (for ERC721)
     * @param tokenIds Token IDs redeemed (for ERC721)
     */
    event HookExecuted(address indexed asset, uint256 amount, uint256[] tokenIds);

}