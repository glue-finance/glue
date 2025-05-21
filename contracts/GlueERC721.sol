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
███╗   ██╗███████╗████████╗        
████╗  ██║██╔════╝╚══██╔══╝        
██╔██╗ ██║█████╗     ██║           
██║╚██╗██║██╔══╝     ██║           
██║ ╚████║██║        ██║           
╚═╝  ╚═══╝╚═╝        ╚═╝           
 
@title Glue V1 for Enumerable ERC721s
@author @BasedToschi
@notice A comprehensive protocol for making enumerable ERC721 NFT collections "sticky" through the Glue Protocol infrastructure
@dev This contract implements the core functionality of the Glue Protocol for NFT collections. The system consists of two primary components:
1. GlueStickERC721: Factory contract that creates and manages individual Glue instances for NFT collections
2. GlueERC721: Implementation contract that gets cloned for each sticky NFT collection

The protocol enables NFT collections to have backing assets by:
- Associating the collection with a unique glue address that can hold collateral (any ERC20 or ETH)
- Allowing users to "unglue" by burning NFTs from the collection to withdraw a proportional amount of collateral
- Supporting batch operations, flash loans, and advanced hook mechanisms for extended functionality

Lore:
-* "Glue Stick" is the factory contract that glues ERC721 tokens.
-* "Sticky Asset" is an asset fueled by glue.
-* "Glue Address" is the address of the glue that is linked to a Sticky Token.
-* "Glued Collaterals" are the collaterals glued to a Sticky Token.
-* "Apply the Glue" is the action of infusing a NFT Collection with glue, making it sticky by creating its Glue Address.
-* "Unglue" is the action of burning the supply of a Sticky Asset to withdraw the corresponding percentage of the collateral.
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
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
* @dev Interfaces for GlueERC20
*/
import {IGlueERC721, IGlueStickERC721, IERC721Burnable} from "./interfaces/IGlueERC721.sol";
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

* @title GlueStickERC721
* @notice Factory contract for deploying and managing glue instances for ERC721 NFT collections
* @dev This contract serves as the entry point for making NFT collections sticky in the Glue Protocol.
* It validates collections, deploys minimal proxies for individual glue instances, and provides
* batch operations across multiple collections. It also coordinates cross-glue flash loans.
*/
contract GlueStickERC721 is IGlueStickERC721 {

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

    // Registry of NFT collections to their glue addresses
    mapping(address => address) private _getGlueAddress;

    // Array of all deployed glue addresses for enumeration
    address[] private _allGlues;

    // Implementation contract address that gets cloned for each collection
    address private immutable _THE_GLUE;

    /**
    * @notice Deploys the implementation contract and initializes the factory
    * @dev Sets up the factory by deploying the implementation contract that will be cloned
    * for each NFT collection that gets glued in the protocol
    *
    * Use case: One-time deployment of the GlueStickERC721 factory to establish
    * the NFT branch of the Glue protocol on a blockchain network
    */
    constructor () {

        // Deploy the implementation contract   
        _THE_GLUE = deployTheGlue();

    }

    /**
    * @notice Prevents reentrancy attacks using transient storage
    * @dev Custom implementation of reentrancy protection using transient storage
    * This approach optimizes gas costs by using tstore/tload instead of state variables
    * while maintaining robust security guarantees for critical functions
    *
    * Use case: Protecting critical functions against potential reentrancy exploits,
    * particularly during NFT and collateral transfers which could contain callbacks
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

        // Initialize the glue contract
        IGlueERC721(glueAddress).initialize(asset);

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
    function batchUnglue(address[] calldata stickyAssets,uint256[][] calldata tokenIds,address[] calldata collaterals,address[] calldata recipients) external override nnrtnt {

        // Validate inputs
        if(stickyAssets.length == 0 || stickyAssets.length != tokenIds.length || recipients.length == 0) 
            revert InvalidInputs();

        // Process each sticky token in the batch
        for(uint256 i; i < stickyAssets.length;) {

            // Get the sticky token
            address stickyAsset = stickyAssets[i];

            // Get the token IDs
            uint256[] calldata tokenIdBatch = tokenIds[i];
            
            // Transfer each token ID individually
            for (uint256 j = 0; j < tokenIdBatch.length; j++) {

                // Transfer the token ID from the caller to this contract
                IERC721(stickyAsset).transferFrom(msg.sender, address(this), tokenIdBatch[j]);
            }
            
            // If there are no token IDs, skip to the next sticky token
            if (tokenIdBatch.length == 0) continue;
            
            // Get the glue address for this sticky token
            address glueAddress = _getGlueAddress[stickyAsset];

            // If the glue address is not set, skip to the next sticky token
            if(glueAddress == address(0) ) continue;

            // Approve each token ID individually
            for (uint256 j = 0; j < tokenIdBatch.length; j++) {

                // Approve the token ID to the glue address
                IERC721(stickyAsset).approve(glueAddress, tokenIdBatch[j]);
            }

            // If there are multiple recipients, validate inputs
            if(recipients.length > 1) {

                // Validate inputs
                if (recipients.length != stickyAssets.length || recipients[i] == address(0)) revert InvalidInputs();

                // Execute unglue for this sticky token
                IGlueERC721(glueAddress).unglue(
                    collaterals,
                    tokenIdBatch,
                    recipients[i]
                );

            // If there is only one recipient, validate inputs
            } else {

                // Validate inputs
                if (recipients[0] == address(0)) revert InvalidInputs();

                // Execute unglue for this sticky token
                IGlueERC721(glueAddress).unglue(
                    collaterals,
                    tokenIdBatch,
                    recipients[0]
                );
            }

            // Increment the index
            unchecked { ++i; }
        }

        // Emit an event to signal the completion of the batch ungluing
        emit BatchUnglueExecuted(stickyAssets, tokenIds, collaterals, recipients);
    }

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
    * @param loanAmount The total amount of collateral to borrow.
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

            // Get the available balance of the glue
            uint256 available = getGlueBalance(glue, collateral);

            // If the available balance is 0, revert
            if(available == 0) revert InvalidGlueBalance(glue, available, collateral);
            
            // If the available balance is greater than 0, calculate the loans
            if (available > 0) {

                // Calculate the amount to borrow
                uint256 toBorrow = loanAmount - totalCollected;

                // If the amount to borrow is greater than the available balance, set the amount to borrow to the available balance
                if (toBorrow > available) toBorrow = available;

                // If the amount to borrow is 0, skip to the next glue
                if(toBorrow == 0) continue;

                // Get the flash loan fee
                uint256 fee = IGlueERC721(glue).getFlashLoanFeeCalculated(toBorrow);
                
                // Store the loan data
                loanData.toBorrow[j] = toBorrow;
                loanData.expectedAmounts[j] = toBorrow + fee;
                loanData.expectedBalances[j] = available + fee;
                totalCollected += toBorrow;
                j++;
            }

            // Increment the index
            unchecked { ++i; }
        }

        // Set the count of the loans
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
            if(!IGlueERC721(glues[i]).loanHandler(
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
    * @notice Deploys the _THE_GLUE contract.
    * @dev This function is only called once when deploying the implementation contract
    * Actual glue instances are created as clones and initialized via initialize()
    * @return address The address of the deployed GlueERC721 contract
    *
    * Use cases:
    * - One-time deployment of the implementation contract for NFT collections
    */
    function deployTheGlue() internal returns (address) {

        // Deploy the implementation contract
        GlueERC721 glueContract = new GlueERC721(address(this));

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
            } else {
                // Get collateral amounts for this sticky token
                (uint256[] memory tokenCollateralAmounts) = IGlueERC721(glueAddress).collateralByAmount(stickyAmounts[i], collaterals);

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
    function checkAsset(address asset) public view override returns (bool isValid) {

        // First check if it supports ERC721 interface
        bytes4 ERC721InterfaceId = 0x80ac58cd; 

        // Try to check if it supports the ERC721 interface
        try IERC165(asset).supportsInterface(ERC721InterfaceId) returns (bool supports721) {

            // If it doesn't support the ERC721 interface, return false
            if (!supports721) {
                return false;
            }
        } catch {

            // If it doesn't support the ERC721 interface, return false
            return false;
        }

        // Then check for totalSupply
        (bool hasTotalSupply, ) = asset.staticcall(abi.encodeWithSignature("totalSupply()"));

        // If it doesn't have a totalSupply, return false
        if (!hasTotalSupply) {
            return false;
        }

        // Return true if it supports the ERC721 interface and has a totalSupply
        return true;
    }

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
    function computeGlueAddress(address asset) public view override returns (address predictedGlueAddress) {

        // Validate inputs
        if(asset == address(0)) revert InvalidAsset(asset);

        // Compute the glue address
        bytes32 salt = keccak256(abi.encodePacked(asset));

        // Return the predicted address
        return Clones.predictDeterministicAddress(_THE_GLUE, salt, address(this));
    }

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
    function isStickyAsset(address asset) public view override returns (bool isSticky, address glueAddress) {

        // Return a boolean, true if the token is sticky and the glue address
        return (_getGlueAddress[asset] != address(0), _getGlueAddress[asset]);
    }

    /** 
    * @notice Retrieves the balance of a given collateral in a glue.
    * @dev Handles both ERC20 collaterals and native ETH (when collateral address is address(0)),
    * providing a unified interface for balance queries that's used throughout the protocol.
    * 
    * @param glue The address of the glue.
    * @param collateral The address of the collateral.
    * @return uint256 The balance of the collateral in the glue.
    *
    * Use cases:
    * - Collateral availability verification for flash loans
    * - Used in getGluesBalances to track the balance of each glue for each collateral
    */
    function getGlueBalance(address glue,address collateral) internal view returns (uint256) {

        // If the collateral is 0, return the balance of the glue
        if(collateral == address(0)) {

            // Return the balance of the collateral
            return glue.balance;

        } else {

            // Return the balance of the collateral
            return IERC20(collateral).balanceOf(glue);
        }
    }

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
    * @param asset The address of the NFT collection to get the glue address for
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
 
* @title GlueERC721
* @notice Implementation contract for individual NFT collection glue instances
* @dev This contract is deployed once and then cloned using minimal proxies for each glued NFT collection.
* It manages collateral holdings, processes NFT ungluing operations, calculates proportional
* withdrawals based on NFT count vs total supply, and facilitates flash loans. The contract 
* implements ERC721Holder for safe NFT receipt during ungluing operations.
*/
contract GlueERC721 is Initializable, ERC721Holder, IGlueERC721 {

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

    /// @notice Dead address used for NFTs that don't support burning
    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @notice Address of the protocol-wide settings contract
    address private constant SETTINGS = 0x9976457c0C646710827bE1E36139C2b73DA6d2f3;
    
    // Immutable reference to factory

    /// @notice Address of the GlueStick factory that created this glue
    address private immutable GLUE_STICK;
    
    // Glue instance state

    /// @notice Address of the ERC721 collection this glue is associated with
    address private STICKY_ASSET;

    /// @notice Flag indicating if the NFT collection doesn't support burning
    bool private notBurnable;

    /// @notice Flag indicating if NFTs are stored in this contract rather than burned/transferred
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
    * Use case: One-time deployment of the implementation contract for NFT collections
    */
    constructor(address _glueStickAddress) {

        // If the glue stick address is 0, revert
        if(_glueStickAddress == address(0)) revert InvalidGlueStickAddress();

        // Set the glue stick address
        GLUE_STICK = _glueStickAddress;
    }

    /**
    * @notice Guards against reentrancy attacks using transient storage
    * @dev Custom implementation of reentrancy protection using transient storage (tstore/tload)
    * instead of a standard state variable, optimizing gas costs while maintaining security
    *
    * Use case: Securing all external functions against reentrancy attacks,
    * particularly important for functions handling NFT and collateral transfers
    */
    modifier nnrtnt() {

        // Create a slot for the reentrancy guard
        bytes32 slot = keccak256(abi.encodePacked(address(this), "ReentrancyGuard"));

        // If the slot is already set, revert
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
    function initialize(address asset) external nnrtnt initializer {

        // If the sender is not the glue stick, revert
        if(msg.sender != GLUE_STICK) revert Unauthorized();

        // If the token address to glue is 0, revert
        if(asset == address(0)) revert InvalidAsset(asset);

        // Set the sticky token
        STICKY_ASSET = asset;

        // Set inital boolean values
        stickySupplyStored = false;
        notBurnable = false;
        bio = BIO.UNCHECKED;
    }

    /**
    * @notice Allows the contract to receive ETH.
    */
    receive() external payable {}

    /**
    * @notice Override ERC721Holder's onERC721Received to only accept STICKY_ASSET
    * @dev This implementation ensures only the STICKY_ASSET can be received during unglue
    *
    * @param operator The address which called `safeTransferFrom` function
    * @param from The address which previously owned the token
    * @param tokenId The NFT identifier which is being transferred
    * @param data Additional data with no specified format
    * @return bytes4 The function selector
    *
    * Use cases:
    * - Ensuring the ONLY ERC721 that can be received is the STICKY_ASSET.
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {

        // Only allow receiving the sticky token
        if (msg.sender != STICKY_ASSET) {
            revert NoAssetsTransferred();
        }
        
        // Call parent implementation
        return super.onERC721Received(operator, from, tokenId, data);
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
    function unglue(address[] calldata collaterals, uint256[] calldata tokenIds, address recipient) external override nnrtnt returns (uint256 supplyDelta, uint256 realAmount, uint256 beforeTotalSupply, uint256 afterTotalSupply) {

        // If no collateral is selected, revert
        if(collaterals.length == 0) revert NoAssetsSelected();

        // If the recipient is 0, set it to the sender
        if (recipient == address(0)) {recipient = msg.sender;}

        // Process the unique token IDs
        realAmount = processUniqueTokenIds(tokenIds);

        // Get the real total supply
        (beforeTotalSupply, afterTotalSupply) = getRealTotalSupply(realAmount);

        // Calculate the supply delta
        supplyDelta = calculateSupplyDelta(realAmount, beforeTotalSupply);

        // Compute the collateral
        computeCollateral(collaterals, supplyDelta, recipient);

        // Emit the unglued event
        emit unglued(recipient, realAmount, beforeTotalSupply, afterTotalSupply, supplyDelta);

        // Return the values
        return (supplyDelta, realAmount, beforeTotalSupply, afterTotalSupply);
    }

    /**
    * @notice Processes token IDs array to remove duplicates and verify ownership
    * @dev Creates a new array with unique token IDs and verifies ownership
    *
    * @param tokenIds Array of token IDs to process
    * @return uniqueCount Number of unique token IDs
    *
    * Use cases:
    * - Removing duplicates from the token IDs array
    * - Verifying ownership of the token IDs
    */
    function processUniqueTokenIds(uint256[] calldata tokenIds) private returns (uint256) {

        // If no token IDs are selected, revert
        if(tokenIds.length == 0) revert NoAssetsSelected();

        // Create a slot for the duplicate token ID check
        bytes32 duplicateSlot = keccak256(abi.encodePacked(address(this), "DuplicateTokenIdCheck"));

        // Initialize the count
        uint256 count = 0;
        
        // Process each token ID
        for (uint256 i = 0; i < tokenIds.length; i++) {

            // Get the token ID
            uint256 tokenId = tokenIds[i];

            // Create a slot for the duplicate token ID check
            bytes32 slot = keccak256(abi.encodePacked(duplicateSlot, tokenId));
            
            // Check if the token ID is a duplicate
            bool isDuplicate;
            assembly {

                // Get the duplicate status
                isDuplicate := tload(slot)

                // Set the duplicate status to true
                tstore(slot, 1)
            }
            
            // If the token ID is not a duplicate
            if (!isDuplicate) {

                // Check if the sender owns the token ID
                if(IERC721(STICKY_ASSET).ownerOf(tokenId) != msg.sender) revert NoAssetsTransferred();

                // Increment the count
                count++;
            }
        }

        // If no token IDs are processed, revert
        if (count == 0) revert NoAssetsTransferred();

        // Create a new array with unique token IDs
        uint256[] memory uniqueTokenIds = new uint256[](count);

        // Initialize the unique count
        uint256 uniqueCount = 0;

        // Process each token ID
        for (uint256 i = 0; i < tokenIds.length; i++) {

            // Get the token ID
            uint256 tokenId = tokenIds[i];

            // Create a slot for the duplicate token ID check
            bytes32 slot = keccak256(abi.encodePacked(duplicateSlot, tokenId));
            
            // Check if the token ID is processed
            bool isProcessed;
            assembly {

                // Get the processed status
                isProcessed := tload(slot)

                // Set the processed status to false
                tstore(slot, 0)
            }

            // If the token ID is processed
            if (isProcessed) {

                // Add the token ID to the unique token IDs array
                uniqueTokenIds[uniqueCount] = tokenId;

                // Increment the unique count
                uniqueCount++;
            }
        }

        // Burn the main tokens
        burnMain(uniqueTokenIds);

        // Execute the hook
        tryHook(address(this), uniqueCount, uniqueTokenIds);

        // If no tokens are transferred, revert
        if (uniqueCount == 0) {
            revert NoAssetsTransferred();
        }

        // Return the unique count
        return uniqueCount;
    }

    /**
    * @notice Calculates the real total supply of the sticky token by excluding balances in dead and burn addresses.
    * This function is used to calculate the total supply before and after the unglue operation.
    *
    * @param realAmount The amount of sticky tokens being unglued
    * @return beforeTotalSupply The total supply before ungluing
    * @return afterTotalSupply The total supply after ungluing
    *
    * Use cases:
    * - Calculating the total supply before and after ungluing
    * - Ensuring accurate supply metrics for fair collateral distribution
    */
    function getRealTotalSupply(uint256 realAmount) private view returns (uint256, uint256) {

        // Get the before total supply
        uint256 beforeTotalSupply = (getNFTTotalSupply() + realAmount) - getNFTBalance(DEAD_ADDRESS);

        // Subtract the balance of the glue
        beforeTotalSupply -= getNFTBalance(address(this));

        // Get the after total supply
        uint256 afterTotalSupply = beforeTotalSupply - realAmount;
        
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
    * @notice Burns the main tokens held by the glue or transfers them to the dead address if burning fails.
    * This function is used to burn the main tokens held by the glue or transfer them to the dead address if burning fails.
    *
    * @param _tokenIds The token IDs to burn or transfer.
    *
    * Use cases:
    * - Burning the main tokens held by the glue.
    * - Transferring the main tokens to the dead address if burning fails.
    */
    function burnMain(uint256[] memory _tokenIds) private {

        // Process each token ID
        for (uint256 i = 0; i < _tokenIds.length; i++) {

            // Get the token ID
            uint256 tokenId = _tokenIds[i];

            // If the token is not burnable, try to burn it
            if (!notBurnable) {

                // Try to burn the token
                try IERC721Burnable(STICKY_ASSET).burn(tokenId) {

                    // Burn successful, continue to next iteration
                    continue;

                } catch {

                    // Set the not burnable flag to true
                    notBurnable = true;
                }
            } 

            // If the token is not burnable and the token is not stored, try to transfer it to the dead address
            if (notBurnable && !stickySupplyStored) {

                // Try to transfer the token to the dead address
                try IERC721(STICKY_ASSET).transferFrom(msg.sender, DEAD_ADDRESS, tokenId) {

                    // Transfer successful, continue to next iteration
                    continue;

                } catch {

                    // Set the sticky token stored flag to true
                    stickySupplyStored = true;
                }
            }

            // If the token is not burnable and the token is stored, try to transfer it to the glue
            if (notBurnable && stickySupplyStored) {

                // Try to transfer the token to the glue
                try IERC721(STICKY_ASSET).transferFrom(msg.sender, address(this), tokenId) {

                    // Transfer successful, continue to next iteration
                    continue;

                } catch {

                    // Revert
                    revert FailedToProcessCollection();
                }
            }
        }
    }

    /**
    * @dev Processes the withdrawals for the given token addresses and amounts.
    * It also checks for duplicates and calculates the asset availability.
    * It also calculates the protocol fee and the recipient amount.
    * It also executes the hook if enabled.
    * It also sends the glue fee and the protocol fee to the glue fee address and the team address respectively.
    * It also sends the recipient amount to the recipient.
    *
    * @param collaterals The addresses of the collateral tokens to withdraw.
    * @param supplyDelta The change in the token supply.
    * @param recipient The address of the recipient.
    *
    * Use cases:
    * - Ungluing assets from the glue.
    * - Sending the unglued assets to the recipient.
    * - Calculating the protocol fee and the recipient amount.
    * - Executing the hook if enabled.
    * - Sending the glue fee and the protocol fee to the glue fee address and the team address respectively.
    */
    function computeCollateral(address[] calldata collaterals, uint256 supplyDelta, address recipient) private {

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
            
            // Check if the collateral is a duplicate
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

            // Calculate the asset availability
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
            if (bio == BIO.UNCHECKED || bio == BIO.HOOK) {

                // Execute the hook
                recipientAmount = tryHook(gluedCollateral, recipientAmount, new uint256[](0));
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

        // Reset the duplicate flags
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
    * @notice Executes a hook based on the token address and returns the hook amount
    * @dev This function assumes all checks are done outside and just executes the hook
    *
    * @param asset The address of the asset
    * @param amount The amount of the asset
    * @param tokenIds The token IDs to execute the hook on
    * @return The amount of tokens consumed by the hook operation
    *
    * Use cases:
    * - Executing the hook if enabled.
    * - Sending the hook amount to the sticky token.
    * - Returning the amount minus the hook amount.
    */
    function tryHook(address asset, uint256 amount, uint256[] memory tokenIds) private returns (uint256) {

        // If the token is the sticky token, execute the hook
        // This hook dont send ammount to the sticky token, but is designed to track for expanded integration the burned IDs.
        if (asset == STICKY_ASSET) {

            if (bio == BIO.HOOK || bio == BIO.UNCHECKED) {

            try IGluedHooks(STICKY_ASSET).executeHook(asset, amount, tokenIds) {
                // Hook executed successfully
            } catch {
                // Hook execution failed, but we continue processing
                // The assets have already been transferred
            }

                // Return 0
                return 0;

            }

            // Return 0
            return 0;
        
        } else {

            // Initialize the hook amount
            uint256 hookAmount;

            // If the hook is unchecked, try to get the hook size
            if (bio == BIO.UNCHECKED) {

                // Try to get the hook size
                try IGluedHooks(STICKY_ASSET).hasHook() returns (bool hasHook) {

                    // If the hook is enabled, set the bio to hook
                    if (hasHook) {

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
            
            // If the hook amount is 0, return the amount
            if (hookAmount == 0) return amount;
            
            // Ensure hook amount doesn't exceed available amount
            hookAmount = hookAmount > amount ? amount : hookAmount;
            
            // If the token is not ETH, transfer the hook amount to the sticky token
            if (asset != ETH_ADDRESS) {

                // Get the balance before
                uint256 balanceBefore = IERC20(asset).balanceOf(STICKY_ASSET);

                // Transfer the hook amount to the sticky token
                IERC20(asset).safeTransfer(STICKY_ASSET, hookAmount);

                // Get the balance after
                uint256 balanceAfter = IERC20(asset).balanceOf(STICKY_ASSET);

                // If the balance after is less than or equal to the balance before, set the hook amount to 0
                if (balanceAfter <= balanceBefore) {

                    // Set the hook amount to 0
                    hookAmount = 0;

                } else {

                    // Set the hook amount to the balance after minus the balance before
                    hookAmount = balanceAfter - balanceBefore;
                    
                }
            } else {

                // Send the hook amount to the sticky token
                payable(STICKY_ASSET).sendValue(hookAmount);

            }
            
            // Call appropriate hook function with try-catch to handle potential failures
            try IGluedHooks(STICKY_ASSET).executeHook(asset, hookAmount, tokenIds) {
                // Hook executed successfully
            } catch {
                // Hook execution failed, but we continue processing
                // The assets have already been transferred
            }

            // Return the amount minus the hook amount
            return amount - hookAmount;
        }
    }

    /**
    * @notice Retrieves the balance of the specified token held by the glue.
    * @dev This function is used to get the balance of the specified token for the given account.
    *
    * @param asset The address of the token contract.
    * @param account The address of the account.
    * @return The balance of the token held by the account.
    *
    * Use cases:
    * - Retrieving the balance of the specified token for the given account.
    */
    function getAssetBalance(address asset, address account) private view returns (uint256) {

        // If the token is ETH, return the balance of the account
        if (asset == ETH_ADDRESS) {

            // Return the balance of the account
            return account.balance;
        } else {

            // Return the balance of the token
            return IERC20(asset).balanceOf(account);
        }
    }

    /**
    * @dev Retrieves the balance of a given ERC721 token for a specific account.
    * @param account The address of the account to check the balance for.
    * @return The balance of the ERC721 token held by the account.
    *
    * Use cases:
    * - Retrieving the balance of the ERC721 token for the given account.
    */
    function getNFTBalance(address account) private view returns (uint256) {

        // If the account is the zero address, return 0
        if (account == address(0)) {

            // Return 0
            return 0;
        }

        // Try to get the balance of the ERC721 token
        try IERC721(STICKY_ASSET).balanceOf(account) returns (uint256 balance) {

            // Return the balance
            return balance;
        } catch {

            // Return 0
            return 0;   
        }
    }

    /**
    * @notice Retrieves the total supply of the specified token.
    * @dev This function is used to get the total supply of the specified token.
    *
    * @return The total supply of the token.
    *
    * Use cases:
    * - Retrieving the total supply of the specified token.
    */
    function getNFTTotalSupply() private view returns (uint256) {

        // Try to get the total supply of the ERC721 token
        uint256 totalSupply = IERC721Enumerable(STICKY_ASSET).totalSupply();

        // Return the total supply
        return totalSupply;
    }

    /**
    * @notice Calculates the asset availability based on the asset balance and supply delta.
    * @dev This function is used to calculate the asset availability based on the asset balance and supply delta.
    *
    * @param assetBalance The balance of the asset.
    * @param supplyDelta The supply delta.
    * @return The calculated asset availability.
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
        try IGlueStickERC721(GLUE_STICK).gluedLoan(glues,collateral,amount,receiver,params) {

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

        // If the token is the sticky token, revert
        if(collateral == STICKY_ASSET) revert InvalidAsset(collateral);

        // If the token is ETH, send the amount to the receiver
        if(collateral == ETH_ADDRESS) {

            // Send the amount to the receiver
            payable(receiver).sendValue(amount);

        } else {

            // If the token is not ETH, transfer the amount to the receiver
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
    function getSupplyDelta(uint256 stickyAmount) public view override returns (uint256 supplyDelta) {

        // Get the real total supply
        (uint256 beforeTotalSupply, ) = getRealTotalSupply(stickyAmount);

        // Return the calculated supply delta
        return calculateSupplyDelta(stickyAmount, beforeTotalSupply);
    }

    /** 
    * @notice Retrieves the adjusted total supply of the Sticky NFT Collection.
    * @dev This function is used to get the adjusted total supply of the Sticky NFT Collection.
    *
    * @return adjustedTotalSupply The adjusted total supply of the Sticky NFT Collection.
    *
    * Use cases:
    * - Retrieving the adjusted and actual total supply of the Sticky NFT Collection.
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
    function getTotalHookSize(address collateral, uint256 collateralAmount) public view override returns (uint256 hookSize) {
        
        // If the collateral is the sticky token, return 0
        if (collateral == STICKY_ASSET) {

            // Return 0
            return 0;
        }
        
        // Try to get inHookSize if the hook is enabled
        if (bio == BIO.HOOK) {

            // Try to get the hook size
            try IGluedHooks(STICKY_ASSET).hooksImpact(collateral, collateralAmount, 0) returns (uint256 size) {

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
    function collateralByAmount (uint256 stickyAmount, address[] calldata collaterals) external view override returns (uint256[] memory amounts) {

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
                uint256 hookSize = getTotalHookSize(gluedCollateral, afterFeeAmount);

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
        return (balances);
    }

    /**
    * @notice Retrieves the balance of the sticky NFTs for the glue contract.
    * @dev This function is used to get the balance of the sticky NFTs for the glue contract.
    *
    * @return stickyAmount The balance of the sticky NFTs.
    *
    * Use cases:
    * - Retrieving the balance of the sticky NFTs for the glue contract.
    */
    function getStickySupplyStored() external view override returns (uint256 stickyAmount) {

        // Return the balance of the sticky token
        return getNFTBalance(address(this));
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
    * @return stickyAsset The address of the sticky NFT collection.
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
    function getSelfLearning() external view override returns (bool noNativeBurn, bool stickySupplyGlued) {

        // Return if not burnable and sticky supply stored flags
        return (notBurnable, stickySupplyStored);
    }

}
