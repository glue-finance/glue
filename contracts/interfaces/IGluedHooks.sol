// SPDX-License-Identifier: BUSL-1.1
// https://github.com/glue-finance/glue/blob/main/LICENCE.txt

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

*/

pragma solidity ^0.8.28;

/**
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