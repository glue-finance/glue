// SPDX-License-Identifier: BUSL-1.1

/**

███████╗████████╗██╗ ██████╗██╗  ██╗██╗   ██╗    
██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝╚██╗ ██╔╝    
███████╗   ██║   ██║██║     █████╔╝  ╚████╔╝     
╚════██║   ██║   ██║██║     ██╔═██╗   ╚██╔╝      
███████║   ██║   ██║╚██████╗██║  ██╗   ██║       
╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝       
 █████╗ ███████╗███████╗███████╗████████╗                       ██╗███████╗ █████╗ ███╗   ██╗██╗                 
██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝                      ██╔╝██╔════╝██╔══██╗████╗  ██║╚██╗               
███████║███████╗███████╗█████╗     ██║                         ██║ ███████╗███████║██╔██╗ ██║ ██║               
██╔══██║╚════██║╚════██║██╔══╝     ██║                         ██║ ╚════██║██╔══██║██║╚██╗██║ ██║              
██║  ██║███████║███████║███████╗   ██║                         ╚██╗███████║██║  ██║██║ ╚████║██╔╝               
╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝                          ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝                 
███╗   ██╗ █████╗ ████████╗██╗██╗   ██╗███████╗  
████╗  ██║██╔══██╗╚══██╔══╝██║██║   ██║██╔════╝  
██╔██╗ ██║███████║   ██║   ██║██║   ██║█████╗    
██║╚██╗██║██╔══██║   ██║   ██║╚██╗ ██╔╝██╔══╝    
██║ ╚████║██║  ██║   ██║   ██║ ╚████╔╝ ███████╗  
╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝             

*/


pragma solidity ^0.8.28;

/**
@dev Interfaces for GlueERC20 and GlueERC721
*/
import {IGlueStickERC20, IGlueERC20} from "./../interfaces/IGlueERC20.sol";
import {IGlueStickERC721, IGlueERC721} from './../interfaces/IGlueERC721.sol';
import {IStickyAsset} from './../interfaces/IStickyAsset.sol';

/**
@dev Library providing high-precision mathematical operations, decimal conversion, and rounding utilities for token calculations
*/
import {GluedMath} from './../libraries/GluedMath.sol';

/**
 * @title Sticky Asset Native Standard
 * @author Basetoschi
 * @notice Minimal abstract contract for Glue Protocol Native Assets integration
 * @dev This provides core interactions with the Glue Protocol that can be used
 * by both ERC20 and ERC721 implementations with minimal overhead
 */
abstract contract StickyAsset is IStickyAsset {

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 
*/

    // GluedMath for calculations
    using GluedMath for uint256;

    // █████╗ Core State and Constants
    // ╚════╝ All variables and constants are declared internal for derived contract access
    //        Inheriting contracts can leverage these properties to build custom logic

    /// @notice Precision factor used for fractional calculations (10^18)
    uint256 internal constant PRECISION = 1e18;

    /// @notice Special address used to represent native ETH in the protocol
    address internal constant ETH_ADDRESS = address(0);

    /// @notice Dead address used for burning tokens that don't support burn functionality
    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @notice Address of the protocol-wide Glue Stick for ERC20s contract
    IGlueStickERC20 internal constant GLUE_STICK_ERC20 = IGlueStickERC20(0x49fc990E2E293D5DeB1BC0902f680A3b526a6C60);

    /// @notice Address of the protocol-wide Glue Stick for ERC721s contract
    IGlueStickERC721 internal constant GLUE_STICK_ERC721 = IGlueStickERC721(0x049A5F502Fd740E004526fb74ef66b7a6615976B);
    
    /// @notice Address of the Glue contract for the token
    address internal immutable GLUE;
    
    /// @notice Flag indicating if the token is fungible
    bool internal immutable FUNGIBLE;

    /// @notice Flag indicating if the token has hooks
    bool internal immutable HOOK;

    /// @notice ERC-7572 compliant contract URI for metadata
    string internal _contractURI;
    
    /**
    * @notice In the constructor it saves contractURI, if has Hooks and if the token is fungible
    * it also glues the token based on the type and approves the GLUE address to spend tokens
    *
    * @param initialContractURI The initial contract URI
    * - Insert the URL to a EIP-7572 compliant JSON file
    * @param fungibleAndHook Array of boolean flags for hooks [FUNGIBLE, HOOK]
    * - [0] = FUNGIBLE (ERC20 = true) or non-fungible (ERC721 = false)
    * - [1] = HOOK (true = hooks are enabled)
    */
    constructor(
        string memory initialContractURI,
        bool[2] memory fungibleAndHook
    ) {
        
        // Set if the token is fungible (ERC20 = true) or non-fungible (ERC721 = false)
        FUNGIBLE = fungibleAndHook[0];

        // Set if the token has hooks (true = hooks are enabled)
        HOOK = fungibleAndHook[1];

        // Set the contract URI
        _contractURI = initialContractURI;

        // Automatically glue the token based on type
        if (fungibleAndHook[0] == true) {

            // Glue the ERC20 token
            GLUE = IGlueStickERC20(GLUE_STICK_ERC20).applyTheGlue(address(this));

            // Approve GLUE address to spend tokens
            (bool approveAllSuccess, ) = address(this).call(
                abi.encodeWithSignature("approve(address,uint256)", GLUE, type(uint256).max)
            );

            // If the approval failed, revert
            if(!approveAllSuccess) {
                revert ApproveFailed();
            }

        } else {

            // Glue the ERC721 token
            GLUE = IGlueStickERC721(GLUE_STICK_ERC721).applyTheGlue(address(this));

            // Approve GLUE address to spend tokens
            (bool approveAllSuccess, ) = address(this).call(
                abi.encodeWithSignature("setApprovalForAll(address,bool)", GLUE, true)
            );

            // If the approval failed, revert
            if(!approveAllSuccess) {
                revert ApproveFailed();
            }
        }
    }

    /**
    * @notice Modifier to check if the caller is the GLUE contract
    * @dev Only the GLUE contract can call the functions that use this modifier
    *
    * Use cases:
    * - Check if the caller is the GLUE contract
    */
    modifier onlyGlue() {

        // If the caller is not the GLUE contract, revert
        if (msg.sender != GLUE) revert OnlyGlue();

        // Continue execution
        _;
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
    function unglue(address[] calldata collaterals,uint256 amount,uint256[] memory tokenIds,address recipient) external override {

        // Check if the token is an ERC20
        if (FUNGIBLE) {

            // If the token is an ERC20, the tokenIds array must be empty
            if (tokenIds.length > 0) {
                revert InvalidTokenIds();
            }

            // Transfer the tokens to the recipient
            (bool transferSuccess, bytes memory returnData) = address(this).call(

                // Encode the transfer function call
                abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), amount)
            );

        // Check the result more carefully
        if (!transferSuccess || (returnData.length > 0 && !abi.decode(returnData, (bool)))) {
            revert TransferFailed();
        }
            
            // Call ERC20 unglue with amount
            IGlueERC20(GLUE).unglue(collaterals, amount, recipient);

        // If the token is an ERC721
        } else {

            // For ERC721 tokens, the amount must be equal to the tokenIds array length
            if (amount > tokenIds.length) {
                revert InvalidTokenIds();
            }

            // For each token ID
            for (uint256 i = 0; i < tokenIds.length; i++) {

                // Transfer the token to the recipient
                (bool transferSuccess, bytes memory returnData) = address(this).call(

                    // Encode the transfer function call
                    abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), tokenIds[i])
                );

                // Check the result more carefully - some ERC721 implementations return bool, others don't
                if (!transferSuccess || (returnData.length > 0 && !abi.decode(returnData, (bool)))) {
                    revert TransferFailed();
                }
            }
            
            // Call ERC721 unglue with tokenIds
            IGlueERC721(GLUE).unglue(collaterals, tokenIds, recipient);
        }
    }

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
    function flashLoan(address collateral,uint256 amount,address receiver,bytes calldata params) external override returns (bool success) {
        
        // Create the glues array including this contract's glue
        address[] memory glues = new address[](1);

        // Add the GLUE address to the glues array
        glues[0] = GLUE;

        // If the token is an ERC20
        if (FUNGIBLE) {

            // Execute the gluedLoan through the Glue Stick
            try IGlueStickERC20(GLUE_STICK_ERC20).gluedLoan(glues,collateral,amount,receiver,params) {

                    // Set the success to true
                    success = true;

                // If the loan operation failed
                } catch {

                    // Set the success to false
                    success = false;
                }

        // If the token is an ERC721
        } else {

            // Execute the gluedLoan through the Glue Stick
            try IGlueStickERC721(GLUE_STICK_ERC721).gluedLoan(glues,collateral,amount,receiver,params) {

                // Set the success to true
                success = true;

            // If the loan operation failed
            } catch {

                // Set the success to false
                success = false;
            }
        }
    }

/**
--------------------------------------------------------------------------------------------------------
▗▖ ▗▖ ▗▄▖  ▗▄▖ ▗▖ ▗▖
▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌▗▞▘
▐▛▀▜▌▐▌ ▐▌▐▌ ▐▌▐▛▚▖ 
▐▌ ▐▌▝▚▄▞▘▝▚▄▞▘▐▌ ▐▌
01001000 01001111 
01001111 01001011                               
*/

    // █████╗ Common external functions
    // ╚════╝ Don't edit the following functions

    /**
    * @notice Returns the size/value for the outgoing hook (when ungluing collateral)
    * @param asset The address of the collateral token
    * @return size The hook size as a percentage (in PRECISION units)
    */
    function hookSize(address asset, uint256 amount) external view override returns (uint256 size) {

        // Check if the hook is enabled
        if (!HOOK) return 0;

        // If the asset is the same as this contract
        if (asset == address(this)) {

            // If the token is an ERC20
            if (FUNGIBLE) {

                // Call the internal implementation method with the adjusted amount
                return _calculateStickyHookSize(amount);

            // If the token is an ERC721
            } else {

                // Return 0
                return 0;
            }
        } else {

            // Call the internal implementation method with the adjusted amount
            return _calculateCollateralHookSize(asset, amount);
        }
    }

    /**
    * @notice Hook function called when ungluing collateral tokens
    * @param asset The address of the collateral token
    * @param amount The amount of tokens being processed by the hook
    * @param tokenIds The token IDs being processed (Only ERC721) always empty for ERC20
    */
    function executeHook(address asset, uint256 amount, uint256[] memory tokenIds) external override onlyGlue {

        // Check if the token is the same as this contract
        if (asset == address(this)) {

            // Call the internal implementation method with the adjusted amount
            // Glue already checked for the balance received, if the token has a tax you
            // receive the actual amount received and not the amount sent
            _processStickyHook(amount, tokenIds);

        // If the token is not the same as this contract
        } else {
            
            // Call the internal implementation method with the adjusted amount
            // Glue already checked for the balance received, if the token has a tax you
            // receive the actual amount received and not the amount sent.
            // If the asset is ETH, you'll receive a true boolean and asset = address(0)

            if (asset == ETH_ADDRESS) {

                // Call the internal implementation method with the adjusted amount
                _processCollateralHook(asset, amount, true);
            } else {

                // Call the internal implementation method with the adjusted amount
                _processCollateralHook(asset, amount, false);
            }

        }

        // Emit the hook executed event
        emit HookExecuted(asset, amount, tokenIds);
    }

    // █████╗ Customizable internal functions
    // ╚════╝ Override the following functions in derived contracts
    //
    //      - _calculateStickyHookSize: Logic for calculating the hook size and the ammount of sticky asset 
    //        to be sent for hook processing) [Only GlueERC20]
    //
    //      - _calculateCollateralHookSize: Logic for calculating the hook size and the ammount of collateral token to be sent for hook processing
    //
    //      - _processStickyHook: Logic for processing the hook for sticky tokens based on ammount received (ERC721 Only Read)
    //
    //      - _processCollateralHook: Logic for processing the hook for collateral tokens based on ammount received

    /**
    * @notice Internal function to calculate the outgoing hook size
    * @dev MUST BE OVERRIDDEN by derived contracts that use hooks
    *      If your contract enables OUT_HOOK_FLAG, you must override this method
    *      The default implementation returns 0, which effectively disables the hook
    * @param amount The amount of tokens being processed by the hook
    * @return size The hook size as a percentage (in PRECISION units)
    */
    function _calculateStickyHookSize(uint256 amount) internal view virtual returns (uint256 size) {

        // Derived contracts must override this if they use out hooks
        if (amount == 0) {return 0;}
        return 0; 
    }

    /**
    * @notice Internal function to calculate the outgoing hook size
    * @dev MUST BE OVERRIDDEN by derived contracts that use hooks
    *      If your contract enables OUT_HOOK_FLAG, you must override this method
    *      The default implementation returns 0, which effectively disables the hook
    * @param asset The address of the token
    * @param amount The amount of tokens being processed by the hook
    * @return size The hook size as a percentage (in PRECISION units)
    */
    function _calculateCollateralHookSize(address asset, uint256 amount) internal view virtual returns (uint256 size) {

        // Derived contracts must override this if they use out hooks
        if (amount == 0) {return 0;}
        if (asset == ETH_ADDRESS) {return 0;}
        return 0; 
    }

    /**
    * @notice Internal implementation of the incoming hook logic
    * @dev Override this method in derived contracts to implement custom hook behavior
    * @param amount The amount of tokens being processed
    * @param tokenIds The token IDs being processed (Only ERC721) always empty for ERC20
    */
    function _processStickyHook(uint256 amount, uint256[] memory tokenIds) internal virtual {
        // Default implementation does nothing
        // Derived contracts should override this
    }

    /**
    * @notice Internal implementation of the outgoing hook logic
    * @dev Override this method in derived contracts to implement custom hook behavior
    * @param asset The address of the collateral token
    * @param amount The amount of tokens being processed
    * @param isETH Whether the token is ETH
    */
    function _processCollateralHook(address asset, uint256 amount, bool isETH) internal virtual {
        // Default implementation does nothing
        // Derived contracts should override this
    }

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▄▖  ▗▄▖ ▗▖    ▗▄▄▖
  █ ▐▌ ▐▌▐▌ ▐▌▐▌   ▐▌   
  █ ▐▌ ▐▌▐▌ ▐▌▐▌    ▝▀▚▖
  █ ▝▚▄▞▘▝▚▄▞▘▐▙▄▄▖▗▄▄▞▘
01010100 01101111 01101111 
01101100 01110011
*/

    // █████╗ Tools to
    // ╚════╝ build easier

    /**
     * @notice Function to manage the EIP-7572 URI changes
     */
    function _updateContractURI(string memory newURI) internal {

        // Update the contract URI
        _contractURI = newURI;
    }

    /**
    * @notice Performs a multiply-divide operation with full precision.
    * @dev Calculates floor(a * b / denominator) with full precision, using 512-bit intermediate values.
    * Throws if the result overflows a uint256 or if the denominator is zero.
    *
    * @param a The multiplicand.
    * @param b The multiplier.
    * @param denominator The divisor.
    * @return result The result of the operation.
    *
    * Use case: When you need to calculate the result of a multiply-divide operation with full precision.
    */
    function _md512(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {

        // Return the result of the operation
        return GluedMath.md512(a, b, denominator);
    }

    /**
    * @notice Performs a multiply-divide operation with full precision and rounding up.
    * @dev Calculates ceil(a * b / denominator) with full precision, using 512-bit intermediate values.
    * Throws if the result overflows a uint256 or if the denominator is zero.
    *
    * @param a The multiplicand.
    * @param b The multiplier.
    * @param denominator The divisor.
    * @return result The result of the operation, rounded up to the nearest integer.
    *
    * Use case: When you need to calculate the result of a multiply-divide operation with full precision and rounding up.
    */
    function _md512Up(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {

        // Return the result of the operation rounding up
        return GluedMath.md512Up(a, b, denominator);
    }

    /**
    * @notice Adjusts decimal places between different token decimals. With this function,
    * you can get the right ammount of tokenOut from a given tokenIn address and amount
    * espressed in tokenIn's decimals.
    * @dev If one of the tokens is ETH, you can use the address(0) as the token address.
    *
    * @param amount The amount to adjust
    * @param tokenIn The address of the input token
    * @param tokenOut The address of the output token
    * @return adjustedAmount The adjusted amount with correct decimal places
    *
    * Use case: When you need to adjust the decimal places operating with two different tokens
    */
    function _adjustDecimals(uint256 amount,address tokenIn,address tokenOut) internal view returns (uint256 adjustedAmount) {

        // Return the adjusted amount
        return GluedMath.adjustDecimals(amount, tokenIn, tokenOut);
    }

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▖ ▗▄▄▄▖ ▗▄▖ ▗▄▄▄ 
▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌  █
▐▛▀▚▖▐▛▀▀▘▐▛▀▜▌▐▌  █
▐▌ ▐▌▐▙▄▄▖▐▌ ▐▌▐▙▄▄▀
01010010 01100101 
01100001 01100100                         
*/

    // █████╗ Functions usable to internally
    // ╚════╝ read the state of the contract

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
    function getcollateralByAmount(uint256 stickyAmount,address[] calldata collaterals) public view override returns (uint256[] memory amounts) {

        // Use the known token type and glue address set in constructor
        if (FUNGIBLE) {

            // Call ERC20 collateralByAmount
            return IGlueERC20(GLUE).collateralByAmount(stickyAmount, collaterals);
        
        } else {

            // Call ERC721 collateralByAmount
            return IGlueERC721(GLUE).collateralByAmount(stickyAmount, collaterals);
        }
    }
    
    /**
    * @notice Retrieves the adjusted total supply of the sticky token.
    * @dev This function is used to get the adjusted total supply of the sticky token.
    *
    * @return adjustedTotalSupply The adjusted and actual total supply of the sticky token.
    *
    * Use cases:
    * - Retrieving the adjusted and actual total supply of the sticky token.
    */
    function getAdjustedTotalSupply() public view override returns (uint256 adjustedTotalSupply) {
        
        // Use the known token type and glue address set in constructor
        if (FUNGIBLE) {

            // Call ERC20 getAdjustedTotalSupply
            return IGlueERC20(GLUE).getAdjustedTotalSupply();
        } else {

            // Call ERC721 getAdjustedTotalSupply
            return IGlueERC721(GLUE).getAdjustedTotalSupply();
        }
    }

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
    function getBalances(address[] calldata collaterals) public view override returns (uint256[] memory balances) {
        
        // Use the known token type and glue address set in constructor
        if (FUNGIBLE) {

            // Call ERC20 getBalances
            return IGlueERC20(GLUE).getBalances(collaterals);
        } else {

            // Call ERC721 getBalances
            return IGlueERC721(GLUE).getBalances(collaterals);
        }
    }

    // █████╗ Functions redable only externally
    // ╚════╝ 

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
    function hooksImpact(address collateral, uint256 collateralAmount, uint256 stickyAmount) external view override returns (uint256 size) {

        // If the token is an ERC20
        if (FUNGIBLE) {

            // Call ERC20 hooksImpact
            uint256 hookSizeIn = _calculateStickyHookSize(stickyAmount);

            // If the hook size is 0
            if (hookSizeIn == 0) {

                // Return the collateral hook size
                return _calculateCollateralHookSize(collateral, collateralAmount);

            // If the hook size is not 0
            } else {

                // Return the hook size
                return GluedMath.md512(hookSizeIn, _calculateCollateralHookSize(collateral, collateralAmount), PRECISION);
            }

        // If the token is an ERC721
        } else {

            // Call ERC721 hooksImpact
            return _calculateCollateralHookSize(collateral, collateralAmount);
        }
    }

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
    function getFlashLoanFeeCalculated(uint256 amount) external view override returns (uint256 fee) {

        // Return the flash loan fee applied to a given amount
        if (FUNGIBLE) {
            return IGlueERC20(GLUE).getFlashLoanFeeCalculated(amount);
        } else {
            return IGlueERC721(GLUE).getFlashLoanFeeCalculated(amount);
        }
    }

    /**
    * @notice Returns the contract URI as EIP-7572
    * @dev This function is used to get the contract URI as EIP-7572
    *
    * @return uRI The contract URI
    *
    * Use cases:
    * - Retrieving the assets information in a common format as EIP-7572
    */
    function contractURI() external view override returns (string memory uRI) {
        return _contractURI;
    }

    /**
    * @notice Returns the flag indicating if the token has hooks
    *
    * @return hook If true the asset has hooks
    *
    * Use cases:
    * - Retrieving the flag indicating if the token has hooks
    */
    function hasHook() external view override returns (bool hook) {
        return HOOK;
    }

    /**
    * @notice Returns the flag indicating if the token is fungible
    * @dev This function is used to get the flag indicating if the token is fungible
    *
    * @return fungible If true the token is fungible (ERC20) if false the token is non-fungible (ERC721)
    *
    * Use cases:
    * - Retrieving the flag indicating if the token is fungible (ERC20 = true) if false the token is non-fungible (ERC721)
    */
    function isFungible() external view override returns (bool fungible) {
        return FUNGIBLE;
    }

    /**
    * @notice Returns the address of the glue contract
    * @dev This function is used to get the address of the glue contract
    *
    * @return glue The address of the glue contract
    *
    * Use cases:
    * - Retrieving the address of the glue contract
    */
    function getGlue() external view override returns (address glue) {
        return GLUE;
    }

    /**
    * @notice Returns the address of the glue stick contract
    * @dev This function is used to get the address of the glue stick contract
    *
    * @return glueStick The address of the glue stick contract
    *
    * Use cases:
    * - Retrieving the address of the glue stick contract
    */
    function getGlueStick() external view override returns (address glueStick) {

        if (FUNGIBLE) {
            return address(GLUE_STICK_ERC20);
        } else {
            return address(GLUE_STICK_ERC721);
        }
    }
}