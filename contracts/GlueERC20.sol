// SPDX-License-Identifier: BUSL-1.1
// https://github.com/glue-finance/glue/blob/main/LICENCE.txt

/**

 ██████╗ ██╗     ██╗   ██╗███████╗          
██╔════╝ ██║     ██║   ██║██╔════╝          
██║  ███╗██║     ██║   ██║█████╗            
██║   ██║██║     ██║   ██║██╔══╝            
╚██████╔╝███████╗╚██████╔╝███████╗          
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝          
██╗   ██╗ ██████╗ ██╗   ██╗██████╗          
╚██╗ ██╔╝██╔═══██╗██║   ██║██╔══██╗         
 ╚████╔╝ ██║   ██║██║   ██║██████╔╝         
  ╚██╔╝  ██║   ██║██║   ██║██╔══██╗         
   ██║   ╚██████╔╝╚██████╔╝██║  ██║         
   ╚═╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝         
████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
   ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
   ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
   ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝            
                                            
@title Glue V1 for ERC20s
@author @BasedToschi
@notice A comprehensive protocol for making any ERC20 token "sticky" through the Glue Protocol infrastructure
@dev This contract implements the core functionality of the Glue Protocol for ERC20 tokens. The system consists of two main contracts:
1. GlueStickERC20: Factory contract that creates and manages individual Glue instances
2. GlueERC20: Implementation contract that gets cloned for each sticky token

The protocol provides a novel mechanism for asset backing. When an ERC20 token is "glued":
- It becomes associated with a unique glue address that can hold collateral (any ERC20 or ETH)
- Users can "unglue" the token by burning a portion of its supply to withdraw a proportional amount of collateral
- Supporting batch operations, flash loans, and advanced hook mechanisms for extended functionality

Lore:
-* "Glue Stick" is the factory contract that glues ERC20 tokens.
-* "Sticky Asset" is an asset fueled by glue.
-* "Glue Address" is the address of the glue that is linked to a Sticky Token.
-* "Glued Collaterals" are the collaterals glued to a Sticky Token.
-* "Apply the Glue" is the action of infusing a token with glue, making it sticky by creating its Glue Address.
-* "Unglue" is the action of burning the supply of a Sticky Token to withdraw the corresponding percentage of the collateral.
-* "Glued Loan" is the action of borrowing collateral from multiple glues.
-* "Glued Hook" is a tool to expand the functionality of the protocol, via integrating the Sticky Asset Standard in your contract.
-* "Sticky Asset Standard" A common tools to implenet in your contract to expand the Glue functions and simplifying the development process.
-* "Sticky Asset Native" SAN is an asset that is natively compatible with the Sticky Asset Standard.
*/

pragma solidity ^0.8.28;

/**
* @dev Imports standard OpenZeppelin implementation, interfaces, and extensions for secure functionalities
*/
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
* @dev Interfaces for GlueERC20
*/
import {IGlueERC20, IGlueStickERC20} from "./interfaces/IGlueERC20.sol";
import {IGluedLoanReceiver} from "./interfaces/IGluedLoanReceiver.sol";
import {IGluedSettings} from "./interfaces/IGluedSettings.sol";
import {IGluedHooks} from "./interfaces/IGluedHooks.sol";

/**
* @dev Library providing high-precision mathematical operations, decimal conversion, and rounding utilities for token calculations
*/
import {GluedMath} from "./libraries/GluedMath.sol";

/**

█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗
╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝

 ██████╗ ██╗     ██╗   ██╗███████╗    ███████╗████████╗██╗ ██████╗██╗  ██╗
██╔════╝ ██║     ██║   ██║██╔════╝    ██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝
██║  ███╗██║     ██║   ██║█████╗      ███████╗   ██║   ██║██║     █████╔╝ 
██║   ██║██║     ██║   ██║██╔══╝      ╚════██║   ██║   ██║██║     ██╔═██╗ 
╚██████╔╝███████╗╚██████╔╝███████╗    ███████║   ██║   ██║╚██████╗██║  ██╗
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝    ╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝
                                                                    
* @title GlueStickERC20
* @notice Factory contract that creates and manages individual glue instances for ERC20 tokens
* @dev This contract acts as the primary entry point to the Glue protocol. It deploys minimal proxies
* using the Clones library to create individual GlueERC20 instances for each token, maintaining a
* registry of all glued tokens and their corresponding glue addresses. It also provides batch operations
* and cross-glue flash loan functionality.
*/
contract GlueStickERC20 is IGlueStickERC20 {

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 
*/
    
    // Import SafeERC20 for ERC20 operations
    using SafeERC20 for IERC20;
    
    // Mapping of token address to its associated glue address
    mapping(address => address) private _getGlueAddress;

    // Array containing all deployed glue addresses for enumeration
    address[] private _allGlues;

    // Implementation contract address that is cloned for each new glue
    address private immutable _THE_GLUE;

    /**
    * @notice Deploys the implementation contract and initializes the factory
    * @dev Calls deployTheGlue() to create the implementation that will be cloned
    * for each token that gets glued
    *
    * Use case: One-time deployment to establish the Glue protocol on a blockchain
    */
    constructor() {

        // Deploy the implementation contract   
        _THE_GLUE = deployTheGlue();

    }

    /**
    * @notice Guards against reentrancy attacks using transient storage
    * @dev Custom implementation of reentrancy protection using transient storage (tstore/tload)
    * instead of a standard state variable, optimizing gas costs while maintaining security
    *
    * Use case: Securing critical functions against potential reentrancy exploits,
    * particularly during collateral transfers
    */
    modifier nnrtnt() {

        // Check if the slot is already set
        bytes32 slot = keccak256(abi.encodePacked(address(this), "ReentrancyGuard"));
        
        // If the slot is already set, revert with a specific error signature
        assembly {

            // If the slot is already set, revert with a specific error signature
            if tload(slot) { 
                mstore(0x00, 0x3ee5aeb5)
                revert(0x1c, 0x04)
            }
            // Set the slot to 1 to indicate the function is being executed
            tstore(slot, 1)
        }

        // Execute the function
        _;  

        // Reset the slot to 0 after the function execution is complete
        assembly {
            tstore(slot, 0)
        }
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
    function applyTheGlue(address asset) external override returns (address glueAddress) {

        // Validate inputs
        if(asset == address(0)) revert InvalidAsset(asset);

        // Check if the token is valid
        (bool isAllowed) = checkAsset(asset);

        // If the token is not valid, revert
        if(!isAllowed) revert InvalidAsset(asset);

        // Check if the token is already glued
        if(_getGlueAddress[asset] != address(0)) revert DuplicateGlue(asset);

        // Generate a salt for the deterministic clone
        bytes32 salt = keccak256(abi.encodePacked(asset));

        // Clone the implementation contract
        glueAddress = Clones.cloneDeterministic(_THE_GLUE, salt);

        // Initialize the glue instance with the token address
        IGlueERC20(glueAddress).initialize(asset);

        // Store the glue address for the token
        _getGlueAddress[asset] = glueAddress;

        // Add the glue address to the array of all glued addresses
        _allGlues.push(glueAddress);

        // Emit an event to signal the addition of a new glue
        emit GlueAdded(asset, glueAddress, _allGlues.length);

        // Return the glue address
        return glueAddress;
    }

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
    function batchUnglue(address[] calldata stickyAssets,uint256[] calldata stickyAmounts,address[] calldata collaterals,address[] calldata recipients) external override nnrtnt {

        // Validate inputs
        if(stickyAssets.length == 0 || stickyAssets.length != stickyAmounts.length || recipients.length == 0) 
            revert InvalidInputs();

        // Process each sticky token in the batch
        for(uint256 i; i < stickyAssets.length;) {

            // Get the sticky token
            address stickyAsset = stickyAssets[i];

            // Get the amount to unglue
            uint256 amount = stickyAmounts[i];

            // Transfer the sticky token from the caller to this contract
            IERC20(stickyAsset).safeTransferFrom(msg.sender, address(this), amount);

            // Get the real balance of the sticky token in this contract
            uint256 realBalance = IERC20(stickyAsset).balanceOf(address(this));

            // If the balance is 0, skip to the next sticky token
            if (realBalance == 0) continue;
            
            // Get the glue address for this sticky token
            address glueAddress = _getGlueAddress[stickyAsset];

            // If the glue address is not set, skip to the next sticky token
            if(glueAddress == address(0) ) continue;

            // Approve the glue address to spend the sticky token
            IERC20(stickyAsset).approve(glueAddress, realBalance);

            // If there are multiple recipients, validate inputs
            if(recipients.length > 1) {

                // Validate inputs
                if (recipients.length != stickyAssets.length || recipients[i] == address(0)) revert InvalidInputs();

                // Execute unglue for this sticky token
                IGlueERC20(glueAddress).unglue(
                    collaterals,
                    realBalance,
                    recipients[i]
                );

            // If there is only one recipient, validate inputs
            } else {

                // Validate inputs
                if (recipients[0] == address(0)) revert InvalidInputs();

                // Execute unglue for this sticky token
                IGlueERC20(glueAddress).unglue(
                    collaterals,
                    realBalance,
                    recipients[0]
                );
            }

            // Increment the index
            unchecked { ++i; }
        }

        // Emit an event to signal the completion of the batch ungluing
        emit BatchUnglueExecuted(stickyAssets, stickyAmounts, collaterals, recipients);

    }

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
    function gluedLoan(address[] calldata glues,address collateral,uint256 loanAmount,address receiver,bytes calldata params) external override nnrtnt {

        // Validate inputs
        if(receiver == address(0)) revert InvalidAddress();
        if(loanAmount == 0) revert InvalidInputs();
        if(glues.length == 0) revert InvalidInputs();

        // Calculate the loans
        LoanData memory loanData = _calculateLoans(glues, collateral, loanAmount);

        // Execute the loans
        _executeLoans(loanData, glues, collateral, receiver);

        // Execute the receiver's callback
        if (!IGluedLoanReceiver(receiver).executeOperation(
            glues[0:loanData.count],
            collateral,
            loanData.expectedAmounts,
            params
        )) revert FlashLoanFailed();

        // Verify the balances
        _verifyBalances(loanData, glues, collateral);
        
    }

    /**
    * @notice Calculates the flash loans for each glue.
    * @dev This function calculates the loans, executes them, and verifies the repayments.
    * @param glues The addresses of the glues to borrow from.
    * @param collateral The address of the collateral to borrow.
    * @param loanAmount The total amount of tokens to borrow.
    * @return loanData The data for the loans.
    *
    * Use cases:
    * - Calculate the ammount to borrow from each glue
    */
    function _calculateLoans(address[] calldata glues, address collateral, uint256 loanAmount) private view returns (LoanData memory loanData) {

        // Initialize the arrays for the loans
        loanData.toBorrow = new uint256[](glues.length);
        loanData.expectedAmounts = new uint256[](glues.length);
        loanData.expectedBalances = new uint256[](glues.length);

        // Initialize the total collected amount
        uint256 totalCollected;

        // Initialize the index for the loans
        uint256 j;

        // Process each glue
        for (uint256 i; i < glues.length;) {

            // If the total collected amount is greater than or equal to the total amount, break
            if (totalCollected >= loanAmount) break;
            
            // Get the glue address
            address glue = glues[i];

            // If the glue address is invalid, revert
            if(glue == address(0)) revert InvalidAddress();

            // Get the initial balance of the glue
            uint256 initialBalance = getGlueBalance(glue, collateral);

            // If the initial balance is 0, revert
            if(initialBalance == 0) revert InvalidGlueBalance(glue, initialBalance, collateral);
            
            // If the initial balance is greater than 0, calculate the loans
            if (initialBalance > 0) {

                // Calculate the amount to borrow
                uint256 toBorrow = loanAmount - totalCollected;

                // If the amount to borrow is greater than the initial balance, set the amount to borrow to the initial balance
                if (toBorrow > initialBalance) toBorrow = initialBalance;

                // If the amount to borrow is 0, skip to the next glue
                if(toBorrow == 0) continue;

                // Get the flash loan fee
                uint256 fee = IGlueERC20(glue).getFlashLoanFeeCalculated(toBorrow);
                
                // Store the loan data
                loanData.toBorrow[j] = toBorrow;
                loanData.expectedAmounts[j] = toBorrow + fee;
                loanData.expectedBalances[j] = initialBalance + fee;
                totalCollected += toBorrow;
                j++;
            }

            // Increment the index
            unchecked { ++i; }
        }

        // Store the count of the loans
        loanData.count = j;

        // If the total collected amount is less than the total amount, revert
        if (totalCollected < loanAmount)
            revert InsufficientLiquidity(totalCollected, loanAmount);

        // Return the loan data
        return loanData;
    }

    /**
    * @notice Executes the flash loans for each glue.
    * @dev This function executes the loans and verifies the repayments.
    * @param loanData The data for the loans.
    * @param glues The addresses of the glues to borrow from.
    * @param collateral The address of the collateral to borrow.
    * @param receiver The address of the receiver.
    *
    * Use cases:
    * - Execute the flash loans
    */
    function _executeLoans(LoanData memory loanData,address[] calldata glues,address collateral,address receiver) private {
        
        // Process each glue
        for (uint256 i; i < loanData.count;) {

            // Execute the loan
            if(!IGlueERC20(glues[i]).loanHandler(
                receiver,
                collateral,
                loanData.toBorrow[i]
            )) revert FlashLoanFailed();

            // Increment the index
            unchecked { ++i; }
        }
    }

    /**
    * @notice Verifies the balances for each glue.
    * @dev This function verifies the balances for each glue.
    * @param loanData The data for the loans.
    * @param glues The addresses of the glues to borrow from.
    * @param collateral The address of the collateral to borrow.
    *
    * Use cases:
    * - Verify the balances for each glue after loans are executed
    */
    function _verifyBalances(LoanData memory loanData,address[] calldata glues,address collateral) private view {

        // Verify the balances
        for (uint256 i; i < loanData.count;) {

            // Get the glue address
            address glue = glues[i];

            // If the glue address is invalid, revert
            if(glue == address(0)) revert InvalidAddress();

            // If the balance is less than the expected balance, revert
            if (getGlueBalance(glue, collateral) < loanData.expectedBalances[i])
                revert RepaymentFailed(glue);

            // Increment the index
            unchecked { ++i; }
        }
    }

    /**
    * @notice Deploys the implementation contract (TheGlue) for cloning.
    * @dev This function is called internally during contract construction.
    * Actual glue instances are created as clones and initialized via initialize()
    * @return address The address of the deployed implementation contract.
    *
    * Use cases:
    * - One-time deployment of the implementation contract for the entire protocol
    */
    function deployTheGlue() private returns (address) {

        // Deploy the implementation contract
        GlueERC20 glueContract = new GlueERC20(address(this));

        // Get the address of the deployed implementation contract
        address glueAddress = address(glueContract);

        // If the address is 0, revert
        if(glueAddress == address(0)) revert FailedToDeployGlue();

        // Return the address of the deployed implementation contract
        return glueAddress;
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
    function getBatchCollaterals(address[] calldata stickyAssets,uint256[] calldata stickyAmounts,address[] calldata collaterals) external view override returns (uint256[][] memory collateralAmounts) {
        // Validate inputs
        if(stickyAssets.length != stickyAmounts.length) revert InvalidInputs();

        // Initialize the memory array for the collateral amounts
        collateralAmounts = new uint256[][](stickyAssets.length);

        // Process each sticky token
        for(uint256 i; i < stickyAssets.length;) {

            // Get the glue address for this sticky token
            address glueAddress = _getGlueAddress[stickyAssets[i]];

            // If the glue address is not set, create an empty array for the collateral amounts
            if(glueAddress == address(0)) {

                // Create empty array for invalid glue addresses
                collateralAmounts[i] = new uint256[](collaterals.length);

            // If the glue address is set, get the collateral amounts
            } else {

                // Get collateral amounts for this sticky token
                (uint256[] memory tokenCollateralAmounts) = IGlueERC20(glueAddress).collateralByAmount(stickyAmounts[i], collaterals);

                // Store the collateral amounts
                collateralAmounts[i] = tokenCollateralAmounts;
            }

            // Increment the index
            unchecked { ++i; }
        }

        // Return the sticky tokens and the collateral amounts
        return collateralAmounts;
    }

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
    function checkAsset(address asset) public view override returns (bool isValid) {

        // Original checks for ERC20 compliance
        (bool hasTotalSupply, ) = asset.staticcall(abi.encodeWithSignature("totalSupply()"));
        (bool hasDecimals, ) = asset.staticcall(abi.encodeWithSignature("decimals()"));

        // If not a valid ERC20, return false
        if (!hasTotalSupply || !hasDecimals) return false;

        // Return true
        return true;
    }

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
    function computeGlueAddress(address asset) external view override returns (address predictedGlueAddress) {

        // Validate inputs
        if(asset == address(0)) revert InvalidAsset(asset);

        // Compute the glue address
        bytes32 salt = keccak256(abi.encodePacked(asset));

        // Return the predicted address
        return Clones.predictDeterministicAddress(_THE_GLUE, salt, address(this));
    }

    /**
    * @notice Checks if a token has been glued and returns its glue address
    * @dev Utility function for external contracts and front-ends to verify asset status
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
    function isStickyAsset(address asset) external view override returns (bool isSticky, address glueAddress) {

        // Return a boolean, true if the token is sticky and the glue address
        return (_getGlueAddress[asset] != address(0), _getGlueAddress[asset]);
    }

    /**
    * @notice Retrieves the balance of a specified token in a glue contract
    * @dev Handles both ERC20 tokens and native ETH (when token address is address(0)),
    * providing a unified interface for balance queries that's used throughout the protocol.
    * 
    * @param glue Address of the glue contract to check
    * @param collateral Address of the token to check the balance of (address(0) for ETH)
    * @return uint256 The balance of the collateral in the glue
    *
    * Use cases:
    * - Collateral availability verification for flash loans
    * - Used in getGluesBalances to track the balance of each glue for each collateral
    */
    function getGlueBalance(address glue,address collateral) internal view returns (uint256) {

        // If the collateral is 0, return the ETH balance of the glue
        if(collateral == address(0)) {

            // Return the balance of the token
            return glue.balance;

        } else {

            // Return the balance of the token
            return IERC20(collateral).balanceOf(glue);
        }
    }

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
    function getGluesBalances(address[] calldata glues, address[] calldata collaterals) external view override returns (uint256[][] memory balances) {

        // Initialize the 2D balances array
        balances = new uint256[][](glues.length);
        
        // Process each glue
        for (uint256 i; i < glues.length;) {
            // Initialize the balances array for this glue
            balances[i] = new uint256[](collaterals.length);
            
            // Process each collateral for this glue
            for (uint256 j; j < collaterals.length;) {
                // Get the balance of this collateral in this glue
                balances[i][j] = getGlueBalance(glues[i], collaterals[j]);
                
                // Increment the collateral index
                unchecked { ++j; }
            }
            
            // Increment the glue index
            unchecked { ++i; }
        }
        
        // Return the 2D balances array
        return balances;
    }

    /**
    * @notice Returns the total number of deployed glues.
    * @return existingGlues The length of the _allGlues array.
    *
    * Use cases:
    * - Informational queries about the total number of deployed glues
    */
    function allGluesLength() external view override returns (uint256 existingGlues) {

        // Return the length of the allGlues array
        return _allGlues.length;
    }

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
    function getGlueAddress(address asset) external view override returns (address glueAddress) {

        // Return the glue address for the given token
        return _getGlueAddress[asset];
    }

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
    function getGlueAtIndex(uint256 index) external view override returns (address glueAddress) {

        // Revert if the index is out of bounds
        if (index >= _allGlues.length) {
            return address(0);
        }
        
        // Return the glue address at the specified index
        return _allGlues[index];
    }
}

/**
                                                                               
█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗
╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝

████████╗██╗  ██╗███████╗     ██████╗ ██╗     ██╗   ██╗███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝ ██║     ██║   ██║██╔════╝
   ██║   ███████║█████╗      ██║  ███╗██║     ██║   ██║█████╗  
   ██║   ██╔══██║██╔══╝      ██║   ██║██║     ██║   ██║██╔══╝  
   ██║   ██║  ██║███████╗    ╚██████╔╝███████╗╚██████╔╝███████╗
   ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝
 
* @title GlueERC20
* @notice Implementation contract for individual token glue instances
* @dev This contract is deployed once and then cloned using minimal proxies for each glued token.
* It manages the core functionality of holding collateral, processing ungluing operations,
* calculating proportional withdrawals, and facilitating flash loans. The contract implements
* advanced fee mechanisms and hook capabilities for extended functionality.
*/
contract GlueERC20 is Initializable, IGlueERC20 {

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 
*/

    // Address for address payable (ETH)
    using Address for address payable;

    // SafeERC20 for IERC20
    using SafeERC20 for IERC20;

    // GluedMath for uint256
    using GluedMath for uint256;

    // Protocol constants
    /// @notice Precision factor used for fractional calculations (10^18)
    uint256 private constant PRECISION = 1e18;
    
    /// @notice Protocol fee percentage in PRECISION units (0.1%)
    uint256 private constant PROTOCOL_FEE = 1e15; 

    /// @notice Flash loan fee percentage in PRECISION units (0.01%)
    uint256 private constant LOAN_FEE = 1e14; 

    /// @notice Special address used to represent native ETH in the protocol
    address private constant ETH_ADDRESS = address(0);

    /// @notice Dead address used for burning tokens that don't support burn functionality
    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @notice Address of the protocol-wide settings contract
    address private constant SETTINGS = 0x9976457c0C646710827bE1E36139C2b73DA6d2f3;
    
    // Immutable reference to factory

    /// @notice Address of the GlueStick factory that created this glue
    address private immutable GLUE_STICK;
    
    // Glue instance state

    /// @notice Address of the ERC20 token this glue is associated with
    address private STICKY_ASSET;

    /// @notice Flag indicating if the token doesn't support burning (transfers to DEAD_ADDRESS instead)
    bool private notBurnable;

    /// @notice Flag indicating if address(0) is included in total supply calculations
    bool private noZero;

    /// @notice Flag indicating if tokens are stored in this contract rather than burned
    bool private stickySupplyStored;

    /// @notice Enum tracking hook capability status (UNCHECKED, NO_HOOK, or HOOK)
    BIO private bio;

    /**
    * @notice Constructor sets the factory address and initializes core variables
    * @dev This constructor is only called once when deploying the implementation contract
    * Actual glue instances are created as clones and initialized via initialize()
    * 
    * @param _glueStickAddress Address of the factory contract that deploys glue instances
    *
    * Use case: One-time deployment of the implementation contract for the entire protocol
    */
    constructor(address _glueStickAddress) {

        // If the glue stick address is 0, revert
        if(_glueStickAddress == address(0)) revert InvalidGlueStickAddress();

        // Set the glue stick address
        GLUE_STICK = _glueStickAddress;
    }

    /**
    * @notice Prevents reentrancy attacks using transient storage
    * @dev Custom implementation of reentrancy protection using transient storage
    * This approach optimizes gas costs by using tstore/tload instead of state variables
    * while maintaining robust security guarantees for critical functions
    *
    * Use case: Securing all external functions against potential attack vectors that
    * could exploit callback patterns during token transfers and ETH movements
    */
    modifier nnrtnt() {

        // Create a slot for the reentrancy guard
        bytes32 slot = keccak256(abi.encodePacked(address(this), "ReentrancyGuard"));

        // If the slot is already set, revert
        assembly {
            if tload(slot) { 
                mstore(0x00, 0x3ee5aeb5)
                revert(0x1c, 0x04)
            }

            // Set the slot to 1
            tstore(slot, 1)
        }

        // Execute the function
        _;

        // Reset the slot to 0
        assembly {
            tstore(slot, 0)
        }
    }

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
    function initialize(address asset) external nnrtnt initializer {

        // If the sender is not the glue stick, revert
        if(msg.sender != GLUE_STICK) revert Unauthorized();

        // If the token address to glue is 0, revert
        if(asset == address(0)) revert InvalidAsset(asset);

        // Set the sticky token
        STICKY_ASSET = asset;

        // Set inital boolean values
        notBurnable = false;
        noZero = false;
        stickySupplyStored = false;
        bio = BIO.UNCHECKED;
    }

    /**
    * @notice Allows the contract to receive ETH.
    */
    receive() external payable {}
    
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
    * @notice Core function that processes ungluing operations to release collateral
    * @dev Handles the complete ungluing workflow: accepting sticky tokens, calculating
    * proportional collateral amounts, applying fees, executing hook logic if enabled,
    * and distributing collateral to the recipient. Implements comprehensive security checks.
    * 
    * @param collaterals Array of collateral token addresses to withdraw
    * @param amount Amount of sticky tokens to burn for collateral withdrawal
    * @param recipient Address to receive the withdrawn collateral
    * @return supplyDelta Calculated proportion of total supply (in PRECISION units)
    * @return realAmount Actual amount of tokens processed after transfer
    * @return beforeTotalSupply Token supply before the unglue operation
    * @return afterTotalSupply Token supply after the unglue operation
    *
    * Use cases:
    * - Redeeming collateral from the protocol by burning sticky tokens
    * - Converting sticky tokens back to their collaterals
    */
    function unglue(address[] calldata collaterals, uint256 amount, address recipient) external override nnrtnt returns (uint256 supplyDelta, uint256 realAmount, uint256 beforeTotalSupply, uint256 afterTotalSupply) {

        // If no collateral is selected, revert
        if(collaterals.length == 0) revert NoCollateralSelected();

        // If no tokens are transferred, revert
        if(amount == 0) revert NoAssetsTransferred();

        // If the recipient is 0, set it to the sender
        if (recipient == address(0)) {recipient = msg.sender;}


        // Use direct return values instead of struct
        (supplyDelta, realAmount, beforeTotalSupply, afterTotalSupply) = initialization(amount, recipient);

        // Directly pass collaterals, supplyDelta and recipient to computeCollateral
        computeCollateral(collaterals, supplyDelta, recipient);

        // Emit the unglued event
        emit unglued(recipient, realAmount, beforeTotalSupply, afterTotalSupply, supplyDelta);

        // Return the values
        return (supplyDelta, realAmount, beforeTotalSupply, afterTotalSupply);
    }

    
    /**
    * @notice First phase of ungluing that handles token transfers and supply calculations
    * @dev Processes the incoming sticky tokens, detects token characteristics,
    * calculates supply metrics, executes hook logic if applicable, and handles token burning.
    * This function includes several token compatibility checks and adaptations.
    * 
    * @param amount Amount of sticky tokens submitted for ungluing
    * @param recipient Address to receive the withdrawn collateral
    * @return supplyDelta Calculated proportion of total supply (in PRECISION units)
    * @return realAmount Actual amount of tokens processed after transfer and hooks
    * @return beforeTotalSupply Token supply before the unglue operation
    * @return afterTotalSupply Token supply after the unglue operation
    *
    * Use cases:
    * - Adapting to different ERC20 implementations (with/without burning support)
    * - Calculating precise proportions for fair collateral distribution
    */
    function initialization(uint256 amount, address recipient) private returns (
        uint256 supplyDelta,
        uint256 realAmount,
        uint256 beforeTotalSupply,
        uint256 afterTotalSupply
    ) {

        // Get the previous glue balance
        uint256 previousGlueBalance = getAssetBalance(STICKY_ASSET, address(this));

        // Transfer the sticky tokens from the sender to the glue
        IERC20(STICKY_ASSET).safeTransferFrom(msg.sender, address(this), amount);
        
        // If the zero address is not considered, check if it should be
        if (!noZero) {
            bool considerAddress0 = checkAddress0Inclusion();
            if (considerAddress0) {
                noZero = true;
            }
        }

        // Get the new glue balance
        uint256 newGlueBalance = getAssetBalance(STICKY_ASSET, address(this));
        
        // If the new glue balance is less than or equal to the previous glue balance, revert
        if (newGlueBalance <= previousGlueBalance) {
            revert TransferFailed(STICKY_ASSET, address(this));
        }

        // Get the real amount
        realAmount = newGlueBalance - previousGlueBalance;

        // Execute hook
        if (bio == BIO.UNCHECKED || bio == BIO.HOOK) {
            realAmount = tryHook(STICKY_ASSET, realAmount, recipient);
        }

        // Get the real total supply
        (beforeTotalSupply, afterTotalSupply) = getRealTotalSupply(realAmount);

        // Calculate the supply delta
        supplyDelta = calculateSupplyDelta(realAmount, beforeTotalSupply);
        
        // Burn tokens if needed
        if (!stickySupplyStored) burnMain(newGlueBalance);
    }

    /**
    * @dev Checks if the zero address (address(0)) is included in the token's total supply calculations.
    * This function attempts a test transfer of 1 wei of sticky token to the zero address and checks if the total supply is affected.
    * This function is used in the first interaction between the sticky token and the glue to determinate the self-learning of the glue.
    * If the token is special it'll be recognized as NoZero = false, otherwise it'll be recognized as NoZero = true.
    *
    * @return bool Returns true if the zero address is included in total supply calculations, false otherwise.
    *
    * Use cases:
    * - Determining if the zero address should be considered in total supply calculations
    * - Ensuring accurate supply metrics for non-standard ERC20 implementations
    */
    function checkAddress0Inclusion() private returns (bool) {

        // Get the initial total supply
        bytes memory data = abi.encodeWithSignature("totalSupply()");
        (, bytes memory result) = STICKY_ASSET.staticcall(data);
        uint256 initialTotalSupply = abi.decode(result, (uint256));

        // Attempt a test transfer of 1 wei of sticky token to the zero address
        data = abi.encodeWithSignature("transfer(address,uint256)", address(0), 1);

        // Call the transfer function
        (bool success, ) = STICKY_ASSET.call(data);

        // If the transfer failed, return true
        if (!success) {
            return true;
        }

        // Get the new total supply
        data = abi.encodeWithSignature("totalSupply()");
        (, result) = STICKY_ASSET.staticcall(data);
        uint256 newTotalSupply = abi.decode(result, (uint256));

        // If the new total supply is the same as the initial total supply, return false
        if (initialTotalSupply == newTotalSupply) {
            return false;
        } else {
            return true;
        }
    }

    /**
    * @notice Calculates the real total supply of the sticky token by excluding balances in dead and burn addresses.
    * This function is used to calculate the total supply before and after the unglue operation.
    *
    * @param _realAmount The amount of sticky tokens.
    * @return beforeTotalSupply The real total supply of the sticky token before the unglue operation
    * @return afterTotalSupply The real total supply of the sticky token after the unglue operation
    *
    * Use cases:
    * - Calculating the total supply before and after the unglue operation
    * - Ensuring accurate supply metrics for fair collateral distribution
    */
    function getRealTotalSupply(uint256 _realAmount) private view returns (uint256, uint256) {

        // Get the before total supply
        uint256 beforeTotalSupply = getTotalSupply(STICKY_ASSET) - getAssetBalance(STICKY_ASSET, DEAD_ADDRESS);
                
        // Subtract the balance of the glue
        beforeTotalSupply -= (getAssetBalance(STICKY_ASSET, address(this)) - _realAmount);
        
        // If the zero address is not considered, subtract the balance of the zero address
        if (!noZero) {
            beforeTotalSupply -= getAssetBalance(STICKY_ASSET, address(0));
        }

        // Get the after total supply
        uint256 afterTotalSupply = beforeTotalSupply - _realAmount;

        // Return the values
        return (beforeTotalSupply, afterTotalSupply);
    }

    /**
    * @notice Calculates the supply delta based on the real amount and real total supply.
    * This function is used to calculate the supply delta based on the real amount and real total supply.
    *
    * @param realAmount The real amount of supply.
    * @param beforeTotalSupply The real total supply.
    * @return The calculated supply delta.
    *
    * Use cases:
    * - Calculating the supply delta based on the real amount and real total supply.
    */
    function calculateSupplyDelta(uint256 realAmount, uint256 beforeTotalSupply) private pure returns (uint256) {

        // Calculate the supply delta
        return GluedMath.md512(realAmount, PRECISION, beforeTotalSupply);
    }

    /**
    * @notice Burns the sticky token supply held by the glue, transfers it to the dead address if burning fails or if both fails, glued it forever.
    * If the token has a burn hook, it will execute it first with the calculated percentage of the balance.
    *
    * @param balance The balance of the sticky token.
    *
    * Use cases:
    * - Burning the sticky token supply held by the glue.
    * - Transferring the sticky token supply to the dead address if burning fails.
    */
    function burnMain(uint256 balance) private {

        // Proceed with normal burn logic
        if (!notBurnable) {

            // Try to burn the sticky token
            (bool success, bytes memory returndata) = STICKY_ASSET.call(abi.encodeWithSelector(0x42966c68, balance));

            // If the burn failed, set the not burnable flag to true
            if (!success || (returndata.length != 0 && !abi.decode(returndata, (bool)))) {

                // Set the not burnable flag to true
                notBurnable = true;
            }
        }
        
        if (notBurnable) {

            // Try to transfer the sticky token to the dead address
            try IERC20(STICKY_ASSET).transfer(DEAD_ADDRESS, balance) returns (bool success) {

                // If the transfer failed, set the sticky token stored flag to true
                if (!success) {

                    // Set the sticky token stored flag to true
                    stickySupplyStored = true;
                }
            } catch {

                // Set the sticky token stored flag to true
                stickySupplyStored = true;
            }
        }
    }

    /**
    * @notice Computes and transfers the collateral for ungluing.
    * @dev This function processes each unique glued address and transfers the corresponding assets.
    * It also checks for duplicates and calculates the asset availability.
    * It also calculates the protocol fee and the recipient amount.
    * It also executes the hook if enabled.
    * It also sends the glue fee and the protocol fee to the glue fee address and the team address respectively.
    * It also sends the recipient amount to the recipient.
    *
    * @param collaterals An array of addresses representing the assets to unglue.
    * @param supplyDelta The change in supply due to ungluing.
    * @param recipient The address that will receive the unglued assets.
    *
    * Use cases:
    * - Ungluing assets from the glue.
    * - Sending the unglued assets to the recipient.
    * - Calculating the protocol fee and the recipient amount.
    * - Executing the hook if enabled.
    * - Sending the glue fee and the protocol fee to the glue fee address and the team address respectively.
    */
    function computeCollateral(address[] memory collaterals, uint256 supplyDelta, address recipient) private {

        // Create a slot for the duplicate address check
        bytes32 duplicateSlot = keccak256(abi.encodePacked(address(this), "DuplicateAddressCheck"));
        
        // Fetch fee information directly from SETTINGS
        (uint256 glueFee, address glueFeeAddress, address teamAddress) = IGluedSettings(SETTINGS).getProtocolFeeInfo();
        
        // Process each collateral
        for (uint256 i = 0; i < collaterals.length; i++) {

            // Get the collateral
            address gluedCollateral = collaterals[i];

            // If the collateral is the sticky token, continue
            if(gluedCollateral == STICKY_ASSET) continue;
            
            // Check for duplicates using transient storage
            bytes32 slot = keccak256(abi.encodePacked(duplicateSlot, gluedCollateral));

            // Check if the collateral is a duplicate
            bool isDuplicate;

            assembly {

                // Get the duplicate flag
                isDuplicate := tload(slot)

                // Set the duplicate flag to true
                tstore(slot, 1)
            }

            // If the collateral is a duplicate, continue
            if (isDuplicate) continue;
            
            // Calculate asset availability directly
            uint256 assetAvailability = GluedMath.md512(getAssetBalance(gluedCollateral, address(this)), supplyDelta, PRECISION);

            // If the asset availability is 0, continue
            if (assetAvailability == 0) continue;
            
            // Calculate fees
            uint256 protocolFeeAmount = GluedMath.md512Up(assetAvailability, PROTOCOL_FEE, PRECISION);

            // Calculate the recipient amount
            uint256 recipientAmount = assetAvailability - protocolFeeAmount;

            // If the recipient amount is 0, continue
            if(recipientAmount == 0) continue;

            // Check if out hook is enabled (bit 1, 0x2) in BIO
            if (bio == BIO.HOOK) {
                
                // Execute the hook
                recipientAmount = tryHook(gluedCollateral, recipientAmount, recipient);

            }

            // Calculate the glue fee amount
            uint256 glueFeeAmount = GluedMath.md512Up(protocolFeeAmount, glueFee, PRECISION);

            // If the glue fee amount is greater than the protocol fee amount, set the glue fee amount to the protocol fee amount
            if (glueFeeAmount > protocolFeeAmount) glueFeeAmount = protocolFeeAmount;
            
            // For ETH transfers
            if (gluedCollateral == ETH_ADDRESS) {

                // Send the glue fee to the glue fee address
                payable(glueFeeAddress).sendValue(glueFeeAmount);

                // If the glue fee amount is less than the protocol fee amount, send the protocol fee to the team address
                if (glueFeeAmount < protocolFeeAmount) {

                    // Send the protocol fee to the team address
                    payable(teamAddress).sendValue(protocolFeeAmount - glueFeeAmount);
                }

                // Send the recipient amount to the recipient
                payable(recipient).sendValue(recipientAmount);

            } else {
                
                // Send the glue fee to the glue fee address
                IERC20(gluedCollateral).safeTransfer(glueFeeAddress, glueFeeAmount);

                // If the glue fee amount is less than the protocol fee amount, send the protocol fee to the team address
                if (glueFeeAmount < protocolFeeAmount) {

                    // Send the protocol fee to the team address
                    IERC20(gluedCollateral).safeTransfer(teamAddress, protocolFeeAmount - glueFeeAmount);
                }

                // Send the recipient amount to the recipient
                IERC20(gluedCollateral).safeTransfer(recipient, recipientAmount);
            }
        }

        // Reset duplicate flags
        for (uint256 i = 0; i < collaterals.length; i++) {

            // Get the collateral
            address gluedCollateral = collaterals[i];

            // Reset the duplicate flag
            bytes32 slot = keccak256(abi.encodePacked(duplicateSlot, gluedCollateral));
            assembly {

                // Reset the duplicate flag
                tstore(slot, 0)
            }
        }
    }

    /**
    * @notice Executes a hook based on the asset address and returns the hook amount
    * @dev This function assumes all checks are done outside and just executes the hook
    *
    * @param asset The address of the asset
    * @param amount The amount of the asset
    * @param recipient Address to receive the withdrawn collateral
    * @return The amount of tokens consumed by the hook operation
    *
    * Use cases:
    * - Executing the hook if enabled.
    * - Sending the hook amount to the sticky token.
    * - Returning the amount minus the hook amount.
    */
    function tryHook(address asset, uint256 amount, address recipient) private returns (uint256) {
        
        // Initialize the hook amount
        uint256 hookAmount;

        // If the hook is unchecked, try to get the hook size
        if (bio == BIO.UNCHECKED) {

            // Try to get the hook size
            try IGluedHooks(STICKY_ASSET).hasHook() returns (bool assetHook) {

                // If the hook is enabled, set the bio to hook
                if (assetHook) {

                    // Set the bio to hook
                    bio = BIO.HOOK;
                } else {

                    // Set the bio to no hook
                    bio = BIO.NO_HOOK;
                }
            } catch {

                // Set the bio to no hook
                bio = BIO.NO_HOOK;
            }
        }
        
        // If the hook is enabled, try to get the hook size
        if (bio == BIO.HOOK) {

            // Try to get the hook size
            try IGluedHooks(STICKY_ASSET).hookSize(asset, amount) returns (uint256 hookSize) {

                // If the hook size is greater than the precision, set the hook size to the precision
                if (hookSize > PRECISION) {
                    hookSize = PRECISION;
                }

                // Calculate the hook amount
                hookAmount = GluedMath.md512(amount, hookSize, PRECISION);

            } catch {

                // If hook size retrieval fails, default to 0
                return amount;
            }
        } else {

            // No hook enabled
            return amount;
        }
        
        // Ensure hook amount doesn't exceed available amount
        hookAmount = hookAmount > amount ? amount : hookAmount;

        // Only when there's actually an amount to transfer
        if (hookAmount > 0) {
            // If the token is not ETH, transfer the hook amount to the sticky token
            if (asset != ETH_ADDRESS) {

                // Get the balance before
                uint256 balanceBefore = IERC20(asset).balanceOf(STICKY_ASSET);

                // Transfer the hook amount to the sticky token
                IERC20(asset).safeTransfer(STICKY_ASSET, hookAmount);

                // Get the balance after
                uint256 balanceAfter = IERC20(asset).balanceOf(STICKY_ASSET);

                // If the balance after is less than the balance before, set the hook amount to 0
                if (balanceAfter < balanceBefore) {

                    // If the balance is less than the balance before, revert
                    revert NoAssetsTransferred();

                } else {

                    // Set the hook amount
                    hookAmount = balanceAfter - balanceBefore;
                }
            } else {

                // Send the hook amount to the sticky token
                payable(STICKY_ASSET).sendValue(hookAmount);
                
            }
        }
        
        // Call appropriate hook function with try-catch to handle potential failures
        try IGluedHooks(STICKY_ASSET).executeHook(asset, hookAmount, new uint256[](0), recipient) {
            // Hook executed successfully
        } catch {
            // Hook execution failed, but we continue processing
            // The assets have already been transferred
        }

        // Return the amount minus the hook amount
        return amount - hookAmount;
    }

    /**
    * @notice Retrieves the balance of the specified token for the given account.
    * @dev This function is used to get the balance of the specified token for the given account.
    *
    * @param asset The address of the token contract.
    * @param account The address of the account.
    * @return The balance of the token for the account.
    *
    * Use cases:
    * - Retrieving the balance of the specified token for the given account.
    */
    function getAssetBalance(address asset, address account) private view returns (uint256) {
        if (asset == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(asset).balanceOf(account);
        }
    }

    /**
    * @notice Retrieves the total supply of the specified token.
    * @dev This function is used to get the total supply of the specified token.
    *
    * @param asset The address of the token contract.
    * @return The total supply of the token.
    *
    * Use cases:
    * - Retrieving the total supply of the specified token.
    */
    function getTotalSupply(address asset) private view returns (uint256) {

        // Get the total supply of the token
        return IERC20(asset).totalSupply();
    }

    /**
    * @notice Calculates the asset availability based on the asset balance and supply delta
    * @dev This function is used to calculate the asset availability based on the asset balance and supply delta.
    *
    * @param assetBalance The balance of the asset
    * @param supplyDelta The supply delta
    * @return The calculated asset availability
    *
    * Use cases:
    * - Calculating the asset availability based on the asset balance and supply delta.
    */
    function calculateAssetAvailability(uint256 assetBalance, uint256 supplyDelta) private pure returns (uint256) {

        // Return the calculated asset availability
        return GluedMath.md512(assetBalance, supplyDelta, PRECISION);
    }

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
    function flashLoan(address collateral,uint256 amount,address receiver,bytes calldata params) external override returns (bool success) {
        
        // Create an array with just this glue address
        address[] memory glues = new address[](1);

        // Set the glue address
        glues[0] = address(this);
        
        // Call the GlueStick's gluedLoan function
        try IGlueStickERC20(GLUE_STICK).gluedLoan(glues,collateral,amount,receiver,params) {

            // Set the success to true
            success = true;

        // If the loan operation failed
        } catch {

            // Set the success to false
            success = false;
        }
    }

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
    function loanHandler(address receiver, address collateral, uint256 amount) external override nnrtnt returns (bool loanSent) {

        // If the sender is not the glue stick, revert
        if(msg.sender != GLUE_STICK) revert Unauthorized();

        // If the collateral is the sticky asset, revert
        if(collateral == STICKY_ASSET) revert InvalidAsset(collateral);

        // If the collateral is ETH, send the amount to the receiver
        if(collateral == ETH_ADDRESS) {

            // Send the amount to the receiver
            payable(receiver).sendValue(amount);

        } else {

            // If the collateral is not ETH, transfer the amount to the receiver
            IERC20(collateral).safeTransfer(receiver, amount);
        }

        // Emit the GlueLoan event
        emit GlueLoan(collateral, amount, receiver);
        
        // Return Status
        return true;
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
    function getSupplyDelta(uint256 stickyAmount) public view override returns (uint256 supplyDelta) {

        // Get the real total supply
        (uint256 beforeTotalSupply, ) = getRealTotalSupply(stickyAmount);

        // Return the calculated supply delta
        return calculateSupplyDelta(stickyAmount, beforeTotalSupply);
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
    function getAdjustedTotalSupply() external view override returns (uint256 adjustedTotalSupply) {

        // Get the real total supply
        (uint256 beforeTotalSupply, ) = getRealTotalSupply(0);

        // Return the adjusted total supply
        return beforeTotalSupply;
    }

    /**
    * @notice Retrieves the protocol fee percentage.
    * @dev This function is used to get the protocol fee percentage.
    *
    * @return protocolFee The protocol fee as a fixed-point number with 18 decimal places.
    *
    * Use cases:
    * - Retrieving the protocol fee percentage fixed to 1e15 = 0.1% | 1e18 = 100%.
    */
    function getProtocolFee() external pure override returns (uint256 protocolFee) {

        // Return the protocol fee
        return (PROTOCOL_FEE);
    }

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
    function getFlashLoanFee() external pure override returns (uint256 flashLoanFee) {

        // Return the flash loan fee
        return (LOAN_FEE);
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
    function getFlashLoanFeeCalculated(uint256 amount) external pure override returns (uint256 fee) {

        // Return the flash loan fee applied to a given amount
        return (GluedMath.md512Up(amount, LOAN_FEE, PRECISION));
    }

    /**
    * @notice Retrieves the total hook size for a sepecific collateral or sticky token.
    * @dev This function is used to get the total hook size for a sepecific collateral or sticky token.
    *
    * @param collateral The address of the collateral token.
    * @param collateralAmount The amount of tokens to calculate the hook size for.
    * @param stickyAmount The amount of sticky tokens to calculate the hook size for.
    * @return hookSize The total hook size.
    *
    * Use cases:
    * - Retrieving the total hook size for a specific collateral.
    */
    function getTotalHookSize(address collateral, uint256 collateralAmount, uint256 stickyAmount) public view override returns (uint256 hookSize) {

        // If the collateral is the sticky token, return 0
        if (collateral == STICKY_ASSET) {

            // Return 0
            return 0;
        }
        
        // Try to get inHookSize if the hook is enabled
        if (bio == BIO.HOOK) {

            // Try to get the hook size
            try IGluedHooks(STICKY_ASSET).hooksImpact(collateral, collateralAmount, stickyAmount) returns (uint256 size) {

                // Return the hook size
                return size;
            } catch {

                // Return 0
                return 0;
            }
        }

        // Return 0
        return 0;
    }

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
    function collateralByAmount(uint256 stickyAmount, address[] calldata collaterals) external view override returns (uint256[] memory amounts) {

        // If the collaterals array is empty, revert
        if(collaterals.length == 0) revert NoCollateralSelected();

        // If the amount is 0, revert
        if(stickyAmount == 0) revert ZeroAmount();

        // Calculate the supply delta based on the sticky token amount
        uint256 supplyDelta = getSupplyDelta(stickyAmount);
        
        // Create array for final unglue amounts
        uint256[] memory finalUnglueAmounts = new uint256[](collaterals.length);
        
        // Process each collateral and calculate available amounts with hooks
        for (uint256 i = 0; i < collaterals.length; i++) {

            // Get the collateral address
            address gluedCollateral = collaterals[i];
            
            // If the collateral is the sticky token, set the unglue amount to 0
            if(gluedCollateral == STICKY_ASSET) {

                // Set the unglue amount to 0
                finalUnglueAmounts[i] = 0;

                // Continue to the next collateral
                continue;
            }
            
            // Get asset balance and calculate initial availability
            uint256 assetBalance = getAssetBalance(gluedCollateral, address(this));
            
            // If the asset balance is greater than 0
            if (assetBalance > 0) {

                // Calculate asset availability based on supply delta
                uint256 assetAvailability = calculateAssetAvailability(assetBalance, supplyDelta);
                
                // Apply protocol fee
                uint256 afterFeeAmount = assetAvailability - GluedMath.md512(assetAvailability, PROTOCOL_FEE, PRECISION);
                
                // Apply hooks if enabled
                uint256 hookSize = getTotalHookSize(gluedCollateral, afterFeeAmount, stickyAmount);

                // If the hook size is greater than 0
                if (hookSize > 0) {

                    // Calculate the hook amount
                    uint256 hookAmount = GluedMath.md512(afterFeeAmount, hookSize, PRECISION);
                    
                    // If the hook amount is greater than the after fee amount, set the hook amount to the after fee amount
                    if (hookAmount > afterFeeAmount) {
                        hookAmount = afterFeeAmount;
                    }
                    
                    // Set the unglue amount to the after fee amount minus the hook amount
                    finalUnglueAmounts[i] = afterFeeAmount - hookAmount;
                } else {

                    // Set the unglue amount to the after fee amount
                    finalUnglueAmounts[i] = afterFeeAmount;
                }
            } else {

                // Set the unglue amount to 0
                finalUnglueAmounts[i] = 0;
            }
        }

        // Return the collaterals and the final unglue amounts
        return (finalUnglueAmounts);
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
    function getBalances(address[] calldata collaterals) external view override returns (uint256[] memory balances) {

        // Create an array for the balances
        balances = new uint256[](collaterals.length);

        // Process each collateral and get the balance
        for (uint256 i = 0; i < collaterals.length; i++) {

            // Get the balance of the collateral
            balances[i] = getAssetBalance(collaterals[i], address(this));
        }

        // Return the collateral addresses and the balances
        return balances;
    }

    /**
    * @notice Retrieves the balance of the sticky asset for the glue contract.
    * @dev This function is used to get the balance of the sticky token for the glue contract.
    *
    * @return stickyAmount The balance of the sticky token.
    *
    * Use cases:
    * - Retrieving the balance of the sticky token for the glue contract.
    */
    function getStickySupplyStored() external view override returns (uint256 stickyAmount) {

        // Return the balance of the sticky token
        return IERC20(STICKY_ASSET).balanceOf(address(this));
    }

    /**
    * @notice Retrieves the settings contract address.
    * @dev This function is used to get the settings contract address.
    *
    * @return settings The address of the settings contract.
    *
    * Use cases:
    * - Retrieving the settings contract address.
    */
    function getSettings() external pure override returns (address settings) {

        // Return the settings contract address
        return SETTINGS;
    }

    /**
    * @notice Retrieves the address of the GlueStick factory contract.
    * @dev This function is used to get the address of the GlueStick factory contract.
    *
    * @return glueStick The address of the GlueStick factory contract.
    *
    * Use cases:
    * - Retrieving the address of the GlueStick factory contract.
    */
    function getGlueStick() external view override returns (address glueStick) {

        // Return the glue stick address
        return GLUE_STICK;
    }

    /**
    * @notice Retrieves the address of the sticky token.
    * @dev This function is used to get the address of the sticky token.
    *
    * @return stickyAsset The address of the sticky token.
    *
    * Use cases:
    * - Retrieving the address of the sticky token.
    */
    function getStickyAsset() external view override returns (address stickyAsset) {

        // Return the sticky token address
        return STICKY_ASSET;
    }

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
    function isExpanded() external view override returns (BIO hooksStatus) {

        // Return the hooks status
        return bio;
    }

    /**
    * @notice Retrieves if the Sticky Asset is natively not burnable, follow the ERC20 standard if the sticky token is permanently stored in the contract.
    * @dev This function is used to get if the Sticky Asset is natively not burnable, follow the ERC20 standard if the sticky token is permanently stored in the contract.
    *
    * @return noNativeBurn A boolean representing if the sticky asset is natively not burnable.
    * @return nonStandard A boolean representing if the sticky asset is standard and address(0) is not counted in the total supply.
    * @return stickySupplyGlued A boolean representing if the sticky token is permanently stored in the contract.
    *
    * Use cases:
    * - Knowing if the Sticky Asset is natively not burnable, follow the ERC20 standard if the sticky token is permanently stored in the contract.
    */
    function getSelfLearning() external view override returns (bool noNativeBurn, bool nonStandard, bool stickySupplyGlued) {

        // Return if not burnable, no zero and sticky supply stored flags
        return (notBurnable, noZero, stickySupplyStored);
    }
}