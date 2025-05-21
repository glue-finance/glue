// SPDX-License-Identifier: BUSL-1.1
// https://github.com/glue-finance/glue/blob/main/LICENCE.txt
/**                                                 

 ██████╗ ██╗     ██╗   ██╗███████╗██████╗                       
██╔════╝ ██║     ██║   ██║██╔════╝██╔══██╗                      
██║  ███╗██║     ██║   ██║█████╗  ██║  ██║                      
██║   ██║██║     ██║   ██║██╔══╝  ██║  ██║                      
╚██████╔╝███████╗╚██████╔╝███████╗██████╔╝                      
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝                       
███████╗███████╗████████╗████████╗██╗███╗   ██╗ ██████╗ ███████╗
██╔════╝██╔════╝╚══██╔══╝╚══██╔══╝██║████╗  ██║██╔════╝ ██╔════╝
███████╗█████╗     ██║      ██║   ██║██╔██╗ ██║██║  ███╗███████╗
╚════██║██╔══╝     ██║      ██║   ██║██║╚██╗██║██║   ██║╚════██║
███████║███████╗   ██║      ██║   ██║██║ ╚████║╚██████╔╝███████║
╚══════╝╚══════╝   ╚═╝      ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝
                                                                 
@title GluedSettings
@author @BasedToschi
@notice A contract for managing the ownership settings and fees in the glue ecosystem.
@dev This contract serves as the single source of truth for various protocol parameters, allowing for controlled fee adjustments
* and secure transitions of critical protocol roles while providing safety mechanisms through permanent locking capabilities

*/

pragma solidity ^0.8.28;

// Interfaces
import {IGluedSettings} from './interfaces/IGluedSettings.sol';

/**
* @title GluedSettings
* @notice A centralized governance contract managing fee configurations and administrative settings for the Glue Protocol ecosystem
* @dev This contract serves as the single source of truth for various protocol parameters, allowing for controlled fee adjustments
* and secure transitions of critical protocol roles while providing safety mechanisms through permanent locking capabilities
*/
contract GluedSettings is IGluedSettings {

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 
*/
    
    // Administrative addresses
    address private _owner;            /// @notice Protocol governance address with full administrative powers
    address private glueFeeAddress;    /// @notice Address receiving the primary fee portion from protocol operations
    address private teamAddress;       /// @notice Address receiving the remaining fee portion (non-glue portion)

    // Protocol fee parameters
    uint256 private expProtocolFee;    /// @notice Protocol expansion fee, applied to expanded Glue operations
    uint256 private swapProtocolFee;   /// @notice Protocol swap fee, applied to swap operations
    uint256 private glueFee;           /// @notice Primary Glue cut - the percentage of protocol fee distributed to the fee receiver 
    uint256 private glueExpFee;        /// @notice Expansion Glue cut - applied to expanded Glue protocol operations
    uint256 private glueSwapFee;       /// @notice trading Glue cut - applied to swap operations
    
    // Granular permission flags
    bool private expProtocolFeeOwnershipRenounced;     /// @notice Permission flag for modifying the expanded protocol fee
    bool private swapProtocolFeeOwnershipRenounced;    /// @notice Permission flag for modifying the swap protocol fee
    bool private glueFeeOwnershipRenounced;            /// @notice Permission flag for modifying the glue protocol cut 
    bool private glueExpFeeOwnershipRenounced;         /// @notice Permission flag for modifying the glue expansion cut
    bool private glueSwapFeeOwnershipRenounced;        /// @notice Permission flag for modifying the glue trading cut
    bool private glueOwnershipRenounced;               /// @notice Permission flag for modifying the glue fee recipient

    // Fee limit constants to enforce parameter boundaries for protocol safety
    uint256 private constant MaxExpProtocolFee= 5e14;    /// @notice Maximum expanded protocol fee: 0.05% (5 * 1e14)
    uint256 private constant MinExpProtocolFee = 1e14;   /// @notice Minimum expanded protocol fee: 0.01% (1 * 1e14)
    uint256 private constant MaxSwapProtocolFee= 9e14;   /// @notice Maximum expanded protocol fee: 0.09% (9 * 1e14)
    uint256 private constant MinSwapProtocolFee = 1e14;  /// @notice Minimum expanded protocol fee: 0.01% (1 * 1e14)
    uint256 private constant MinGlueFee = 5e17;          /// @notice Minimum Glue protocol cut: 50% (5 * 1e17)
    uint256 private constant MaxGlueFee = 1e18;          /// @notice Maximum Glue protocol cut: 100% (1 * 1e18)
    uint256 private constant MinGlueExpFee = 1e17;       /// @notice Minimum Glue expansion cut: 10% (1 * 1e17)
    uint256 private constant MaxGlueExpFee = 1e18;       /// @notice Maximum Glue expansion cut: 100% (1 * 1e18)
    uint256 private constant MinGlueSwapFee = 1e17;      /// @notice Minimum Glue trading cut: 10% (1 * 1e17)
    uint256 private constant MaxGlueSwapFee = 1e18;      /// @notice Maximum Glue trading cut: 100% (1 * 1e18)
    
    /**
    * @notice Constructor initializes the contract with default settings and permissions
    * @dev Sets initial fees, addresses, and administrative permissions with the deployer as the default owner
    * Use case: Contract deployment to establish protocol governance framework
    */
    constructor() {
        _owner = msg.sender;                /// @notice Set the deployer as the owner
        teamAddress = msg.sender;           /// @notice Set the deployer as the team address
        glueFeeAddress = msg.sender;        /// @notice Set the deployer as the glue fee address
        expProtocolFee = 5e14;              /// @notice 0.05% Initialization (5 * 1e14)
        swapProtocolFee = 9e14;             /// @notice 0.09% Initialization (9 * 1e14)
        glueFee = 5e17;                     /// @notice 50% Initialization (5 * 1e17)
        glueExpFee = 1e17;                  /// @notice 10% Initialization (1 * 1e17)
        glueSwapFee = 1e17;                 /// @notice 10% Initialization (1 * 1e17)
    }


    /**
    * @notice Restricts function access to the protocol owner
    * @dev Ensures critical protocol configuration functions are only executable by the governance address
    *
    * Use case: Access control for specific administrative functions with potential protocol-wide impact
    */
    modifier onlyOwner() {

        // If the caller is not the owner, revert
        if (msg.sender != _owner) revert OwnershipNotGranted();

        // Continue execution
        _;
    }

    /**
    * @notice Restricts function access to the protocol team address
    * @dev Ensures critical protocol configuration functions are only executable by the team address
    *
    * Use case: Access control for specific administrative functions with potential protocol-wide impact
    */
    modifier onlyTeam() {

        // If the caller is not the team address, revert
        if (msg.sender != teamAddress) revert OwnershipNotGranted();

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

    // █████╗ Management Addresses
    // ╚════╝ Owner: Can update most of the parameters
    //        Team: Can receive portion of protocol fees
    //        Glue: Can receive glue protocol fees

    /**
    * @notice Transfers governance control to a new owner address
    * @dev Critical operation that shifts all admin capabilities to the provided address
    *
    * @param newOwner The address of the new contract owner that will receive full administrative control
    *
    * Use case: Transferring protocol control during governance transitions or to multisig/DAO control
    */
    function transferOwnership(address newOwner) external override onlyOwner {

        // Check if the new owner is not the zero address
        if (newOwner == address(0)) revert InvalidInputs();

        // Store the previous owner
        address previousOwner = _owner;

        // Update the owner to the new owner
        _owner = newOwner;

        // Emit the ownership transfer event
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
    * @notice Sets the team address that receives remaining protocol fee portion
    * @dev Only the current team address can update this to ensure secure transitions
    *
    * @param newTeamAddress The new address to receive the team's share of protocol fees
    *
    * Use case: Transitioning team treasury management or updating protocol revenue destinations
    */
    function setTeamAddress(address newTeamAddress) external override onlyTeam {

        // Check if the new team address is not the zero address
        if (newTeamAddress == address(0)) revert InvalidInputs();

        // Store the previous team address
        address previousTeamAddress = teamAddress;

        // Update the team address
        teamAddress = newTeamAddress;

        // Emit the team address updated event
        emit TeamAddressUpdated(previousTeamAddress, newTeamAddress);
    }

        /**
    * @notice Sets the address that receives the main glue fee portion
    * @dev Updates the destination for glue protocol fees, impacting protocol revenue distribution
    *
    * @param newGlueFeeAddress The new address to receive the glue fee revenue share
    *
    * Use case: Redirecting protocol revenue to new treasury contracts or revenue management systems
    */
    function setGlueFeeAddress(address newGlueFeeAddress) external override onlyOwner() {

        // Check if the owner has the permission to update the glue fee address
        if (glueOwnershipRenounced) revert OwnershipNotGranted();

        // Check if the new glue fee address is not the zero address
        if (newGlueFeeAddress == address(0)) revert InvalidInputs();

        // Store the previous glue fee address
        address previousGlueFeeAddress = glueFeeAddress;

        // Update the glue fee address
        glueFeeAddress = newGlueFeeAddress;

        // Emit the glue fee address updated event
        emit GlueFeeAddressUpdated(previousGlueFeeAddress, newGlueFeeAddress);
    }

    /**
    * @notice Permanently renounces ownership of the contract
    * @dev Irreversibly sets owner to address(0), removing all governance capabilities
    *
    * Use case: Protocol decentralization milestone or transitioning to fully immutable operations
    */
    function renounceOwnership() external override onlyOwner {

        // Store the previous owner
        address previousOwner = _owner;

        // Update the owner to the zero address
        _owner = address(0);

        // Emit the ownership transfer event
        emit OwnershipTransferred(previousOwner, address(0));
    }

    // █████╗ Protocol Fees
    // ╚════╝ The total fee that affect expanded glue products
    //        The Glue V1 protocol fee is not affected by this options, that one is fixed at 0.1%

    /**
    * @notice Updates the expanded protocol fee percentage
    * @dev Controls the fee applied to expanded glue protocol operations, bounded by min/max safety limits
    *
    * @param newExpProtocolFee The new expanded protocol fee percentage (in PRECISION units)
    *
    * Use case: Fee adjustment in response to market conditions or protocol revenue requirements
    */
    function updateExpProtocolFee(uint256 newExpProtocolFee) external override onlyOwner {

        // Check if the owner has the permission to update the expanded protocol fee
        if (expProtocolFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Check if the new expanded protocol fee is not greater than the maximum limit
        if (newExpProtocolFee > MaxExpProtocolFee) revert InvalidInputs();

        // Check if the new expanded protocol fee is not less than the minimum limit
        if (newExpProtocolFee < MinExpProtocolFee) revert InvalidInputs();

        // Update the expanded protocol fee
        expProtocolFee = newExpProtocolFee;

        // Emit the expanded protocol fee updated event
        emit ExpProtocolFeeUpdated(newExpProtocolFee);
    }

    /**
    * @notice Updates the swap protocol fee percentage
    * @dev Controls the fee applied to swap operations, bounded by min/max safety limits
    *
    * @param newSwapProtocolFee The new swap protocol fee percentage (in PRECISION units)
    *
    * Use case: Fee adjustment in response to market conditions or protocol revenue requirements
    */
    function updateSwapProtocolFee(uint256 newSwapProtocolFee) external override onlyOwner {

        // Check if the owner has the permission to update the swap protocol fee
        if (swapProtocolFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Check if the new swap protocol fee is not greater than the maximum limit
        if (newSwapProtocolFee > MaxSwapProtocolFee) revert InvalidInputs();

        // Check if the new swap protocol fee is not less than the minimum limit
        if (newSwapProtocolFee < MinSwapProtocolFee) revert InvalidInputs();

        // Update the swap protocol fee
        swapProtocolFee = newSwapProtocolFee;

        // Emit the swap protocol fee updated event
        emit SwapProtocolFeeUpdated(newSwapProtocolFee);
    }

    // █████╗ Glue Cut
    // ╚════╝ The portion of the protocol fees that are distributed to the glue fee address

    /**
    * @notice Updates the glue fee percentage for the Glue V1 protocol
    * @dev Sets the percentage of protocol fees distributed to the glue fee receiver
    *
    * @param newGlueFee The new main glue fee percentage (in PRECISION units)
    *
    * Use case: Adjusting fee distribution between protocol stakeholders based on governance decisions
    */
    function updateGlueFee(uint256 newGlueFee) external override onlyOwner {

        // Check if the owner has the permission to update the glue fee
        if (glueFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Check if the new glue fee is not greater than the maximum limit
        if (newGlueFee > MaxGlueFee) revert InvalidInputs();

        // Check if the new glue fee is not less than the minimum limit
        if (newGlueFee < MinGlueFee) revert InvalidInputs();

        // Update the glue fee
        glueFee = newGlueFee;

        // Emit the glue fee updated event
        emit GlueFeeUpdated(newGlueFee);
    }

    /** 
    * @notice Updates the glue expansions fee percentage
    * @dev Controls the fee percentage applied specifically to protocol expansion operations
    *
    * @param newGlueExpFee The new glue expansion fee percentage (in PRECISION units)
    *
    * Use case: Fine-tuning economics for protocol expansion
    */
    function updateGlueExpFee(uint256 newGlueExpFee) external override onlyOwner {

        // Check if the owner has the permission to update the glue expansion fee
        if (glueExpFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Check if the new glue expansion fee is not greater than the maximum limit
        if (newGlueExpFee > MaxGlueExpFee) revert InvalidInputs();

        // Check if the new glue expansion fee is not less than the minimum limit
        if (newGlueExpFee < MinGlueExpFee) revert InvalidInputs();

        // Update the glue expansion fee
        glueExpFee = newGlueExpFee;

        // Emit the glue expansion fee updated event
        emit GlueExpFeeUpdated(newGlueExpFee);
    }

    /**
    * @notice Updates the glue swap fee percentage
    * @dev Controls the fee percentage applied specifically to protocol swap operations
    *
    * @param newGlueSwapFee The new glue swap fee percentage (in PRECISION units)
    *
    * Use case: Fine-tuning economics for protocol swap operations
    */
    function updateGlueSwapFee(uint256 newGlueSwapFee) external override onlyOwner {

        // Check if the owner has the permission to update the glue swap fee
        if (glueSwapFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Check if the new glue swap fee is not greater than the maximum limit
        if (newGlueSwapFee > MaxGlueSwapFee) revert InvalidInputs();

        // Check if the new glue swap fee is not less than the minimum limit
        if (newGlueSwapFee < MinGlueSwapFee) revert InvalidInputs();

        // Update the glue swap fee
        glueSwapFee = newGlueSwapFee;

        // Emit the glue swap fee updated event
        emit GlueSwapFeeUpdated(newGlueSwapFee);
    }

    // █████╗ Granular Permissions
    // ╚════╝ The permissions that can be permanently removed to lock the protocol parameters

    /**
    * @notice Permanently removes the ability to modify expanded protocol fees
    * @dev Irreversibly locks the expanded protocol fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeExpProtocolFeeOwnership() external override onlyOwner {

        // Check if the owner has the permission to update the expanded protocol fee
        if (expProtocolFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Update the expanded protocol fee ownership
        expProtocolFeeOwnershipRenounced = true;

        // Emit the expanded protocol fee ownership removed event
        emit ExpProtocolFeeOwnershipRemoved();
    }

    /**
    * @notice Permanently removes the ability to modify the swap protocol fee
    * @dev Irreversibly locks the swap protocol fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeSwapProtocolFeeOwnership() external override onlyOwner {

        // Check if the owner has the permission to update the swap protocol fee
        if (swapProtocolFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Update the swap protocol fee ownership
        swapProtocolFeeOwnershipRenounced = true;

        // Emit the swap protocol fee ownership removed event
        emit SwapProtocolFeeOwnershipRemoved();
    }

    /**
    * @notice Permanently removes the ability to change the glue fee address
    * @dev Irreversibly locks the glue fee recipient address
    *
    * Use case: Granular control over protocol parameters
    */
    function removeGlueOwnership() external override onlyOwner {

        // Check if the owner has the permission to update the glue fee
        if (glueOwnershipRenounced) revert OwnershipNotGranted();

        // Update the glue fee ownership
        glueOwnershipRenounced = true;

        // Emit the glue fee ownership removed event
        emit GlueOwnershipRemoved();
    }

    /**
    * @notice Permanently removes the ability to modify the glue fee percentage
    * @dev Irreversibly locks the glue fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeGlueFeeOwnership() external override onlyOwner {

        // Check if the owner has the permission to update the glue fee
        if (glueFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Update the glue fee ownership
        glueFeeOwnershipRenounced = true;

        // Emit the glue fee ownership removed event
        emit GlueFeeOwnershipRemoved();
    }

    /** 
    * @notice Permanently removes the ability to modify the glue expansion fee
    * @dev Irreversibly locks the glue expansion fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeGlueExpFeeOwnership() external override onlyOwner {

        // Check if the owner has the permission to update the glue expansion fee
        if (glueExpFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Update the glue expansion fee ownership
        glueExpFeeOwnershipRenounced = true;

        // Emit the glue expansion fee ownership removed event
        emit GlueExpFeeOwnershipRemoved();
    }

    /**
    * @notice Permanently removes the ability to modify the glue swap fee
    * @dev Irreversibly locks the glue swap fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeGlueSwapFeeOwnership() external override onlyOwner {

        // Check if the owner has the permission to update the glue swap fee
        if (glueSwapFeeOwnershipRenounced) revert OwnershipNotGranted();

        // Update the glue swap fee ownership
        glueSwapFeeOwnershipRenounced = true;

        // Emit the glue swap fee ownership removed event
        emit GlueSwapFeeOwnershipRemoved();
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

    // █████╗ Management Addresses
    // ╚════╝ Owner: Can update most of the parameters
    //        Team: Can receive portion of protocol fees
    //        Glue: Can receive glue protocol fees

    /**
    * @notice Retrieves the current owner address
    * @dev Provides public access to the address of the contract owner
    *
    * @return owner The current owner address
    *
    * Use case: Integration with protocol dashboards or verification of governance authority
    */
    function getOwner() public view override returns (address owner) {

        // Return the owner address
        return _owner;
    }

    /**
    * @notice Retrieves the current team address
    * @dev Provides public access to the address receiving the team's protocol fee share
    *
    * @return team The current team address configured to receive protocol fees
    *
    * Use case: Integration with protocol dashboards or verification of fee destinations
    */
    function getTeamAddress() public view override returns (address team) {

        // Return the team address
        return teamAddress;
    }

    /**
    * @notice Retrieves the current glue fee address
    * @dev Provides public access to the address receiving the glue portion of protocol fees
    *
    * @return glue The current glue fee address configured to receive protocol fees
    *
    * Use case: Protocol analytics, fee flow verification, or integration with monitoring systems
    */
    function getGlue() public view override returns (address glue) {

        // Return the glue fee address
        return glueFeeAddress;
    }

    // █████╗ Protocol Fees
    // ╚════╝ The total fee that affect expanded glue products
    //        The Glue V1 protocol fee is not affected by this options, that one is fixed at 0.1%
    
    /**
    * @notice Retrieves the current expanded protocol fee percentage
    * @dev Provides public access to the fee rate applied to expanded protocol operations
    *
    * @return expansionsFee The current expansions protocol fee percentage (in PRECISION units)
    *
    * Use case: Fee calculation in expansion modules or client-side fee estimations
    */
    function getExpansionsFee() external view override returns (uint256 expansionsFee) {

        // Return the expansions fee
        return expProtocolFee;
    }

    /**
    * @notice Retrieves the current swap protocol fee percentage
    * @dev Provides public access to the fee rate applied to swap operations
    *
    * @return tradingFee The current swap protocol fee percentage (in PRECISION units)
    *
    * Use case: Fee calculation in swap modules or client-side fee estimations
    */
    function getTradingFee() external view override returns (uint256 tradingFee) {

        // Return the trading fee
        return swapProtocolFee;
    }

    // █████╗ Glue Cut
    // ╚════╝ The portion of the protocol fees that are distributed to the glue fee address

    /**
    * @notice Retrieves the current glue fee percentage
    * @dev Provides the percentage of protocol fees allocated to the glue fee address
    *
    * @return glueProtocolCut The current glue fee percentage (in PRECISION units)
    *
    * Use case: Fee distribution calculations or protocol revenue projections
    */
    function getGlueProtocolCut() public view override returns (uint256 glueProtocolCut) {

        // Return the glue protocol cut
        return glueFee;
    }

    /**
    * @notice Retrieves the current glue expansion fee percentage
    * @dev Provides the percentage applied specifically to expansion operations
    *
    * @return glueExpansionsCut The current glue expansion fee percentage (in PRECISION units)
    *
    * Use case: Protocol expansion planning or economic impact analysis
    */
    function getGlueExpansionsCut() public view override returns (uint256 glueExpansionsCut) {

        // Return the glue expansions cut
        return glueExpFee;
    }

    /**
    * @notice Retrieves the current glue swap fee percentage
    * @dev Provides the percentage applied specifically to swap operations
    *
    * @return glueTradingCut The current glue swap fee percentage (in PRECISION units)
    *
    * Use case: Protocol swap planning or economic impact analysis
    */
    function getGlueTradingCut() public view override returns (uint256 glueTradingCut) {

        // Return the glue trading cut
        return glueSwapFee;
    }

    // █████╗ Batch Info
    // ╚════╝ Functions designed to batch information retrieval for protocols interactions and UX
    
    /**
    * @notice Retrieves complete protocol fee configuration information
    * @dev Consolidated getter for core fee distribution parameters in a single call
    *
    * @return glueProtocolCut The portion of the protocol fees that are distributed to the glue fee address
    * @return glue The address receiving the glue portion of fees
    * @return team The address receiving the team portion of fees
    *
    * Use case: Efficient fee data retrieval for protocol operations and integrations
    */
    function getProtocolFeeInfo() external view override returns (uint256 glueProtocolCut, address glue, address team) {

        // Return the protocol fee info
        return (glueFee, glueFeeAddress, teamAddress);
    }

    /**
    * @notice Retrieves extended protocol fee configuration including expansion parameters
    * @dev Consolidated getter for all fee parameters in a single call
    *
    * @return expansionsFee The current expanded protocol fee percentage
    * @return glueExpansionsCut The current glue expansion fee percentage
    * @return glue The address receiving the glue portion of fees
    * @return team The address receiving the team portion of fees
    *
    * Use case: Complete fee data retrieval for expansion modules and advanced protocol integrations
    */
    function getExpansionsFeeInfo() external view override returns (uint256 expansionsFee, uint256 glueExpansionsCut, address glue, address team) {

        // Return the expanded protocol fee info
        return (expProtocolFee, glueExpFee, glueFeeAddress, teamAddress);
    }

    /**
    * @notice Retrieves extended protocol fee configuration including swap parameters
    * @dev Consolidated getter for all fee parameters in a single call
    *
    * @return tradingFee The current swap protocol fee percentage
    * @return glueTradingCut The current glue swap fee percentage
    * @return glue The address receiving the glue portion of fees
    * @return team The address receiving the team portion of fees
    *
    * Use case: Complete fee data retrieval for swap modules and advanced protocol integrations
    */
    function getTradingFeeInfo() external view override returns (uint256 tradingFee, uint256 glueTradingCut, address glue, address team) {

        // Return the swap protocol fee info
        return (swapProtocolFee, glueSwapFee, glueFeeAddress, teamAddress);
    }

    /**
    * @notice Retrieves the current state of all protocol governance permissions
    * @dev Provides a consolidated view of which protocol parameters can still be modified
    *
    * @return expProtocolFeeRenounced The changeable status of expanded protocol fee
    * @return swapProtocolFeeRenounced The changeable status of swap protocol fee
    * @return glueProtocolCutRenounced The changeable status of glue protocol cut
    * @return glueExpansionsCutRenounced The changeable status of glue expansion cut
    * @return glueTradingCutRenounced The changeable status of glue trading cut
    * @return glueAddressRenounced The changeable status of glue fee receiver
    *
    * Use case: Protocol governance dashboards or immutability verification for integrators
    */
    function getGlueOwnershipStatus() external view override returns (bool expProtocolFeeRenounced, bool swapProtocolFeeRenounced, bool glueProtocolCutRenounced, bool glueExpansionsCutRenounced, bool glueTradingCutRenounced, bool glueAddressRenounced) {

        // Check if the owner is the zero address
        if (_owner == address(0)) {
            return (true, true, true, true, true, true);
        }

        // Return the glue ownership status
        return (expProtocolFeeOwnershipRenounced, swapProtocolFeeOwnershipRenounced, glueFeeOwnershipRenounced, glueExpFeeOwnershipRenounced, glueSwapFeeOwnershipRenounced, glueOwnershipRenounced);
    }

    // █████╗ Fee Ranges
    // ╚════╝ Information about the minimum and maximum values for each fees and glue cuts

    /**
    * @notice Retrieves the current expanded protocol fee range
    * @dev Provides public access to the minimum and maximum expanded protocol fee values
    *
    * @return minFee The minimum expansions fee percentage
    * @return maxFee The maximum expansions fee percentage
    *
    * Use case: Fee calculation in expansion modules or client-side fee estimations
    */
    function getExpansionsFeeRange() external pure override returns (uint256 minFee, uint256 maxFee) {

        // Return the expansions fee range
        return (MinExpProtocolFee, MaxExpProtocolFee);
    }

    /**
    * @notice Retrieves the current swap protocol fee range
    * @dev Provides public access to the minimum and maximum swap protocol fee values
    *
    * @return minFee The minimum trading fee percentage
    * @return maxFee The maximum trading fee percentage
    *
    * Use case: Fee calculation in swap modules or client-side fee estimations
    */
    function getTradingFeeRange() external pure override returns (uint256 minFee, uint256 maxFee) {

        // Return the trading fee range
        return (MinSwapProtocolFee, MaxSwapProtocolFee);
    }

    /**
    * @notice Retrieves the current glue protocol cut range
    * @dev Provides public access to the minimum and maximum glue protocol cut values
    *
    * @return minCut The minimum glue cut from protocol fee percentage
    * @return maxCut The maximum glue cut from protocol fee percentage
    *
    * Use case: Fee distribution calculations or protocol revenue projections
    */
    function getGlueProtocolCutRange() external pure override returns (uint256 minCut, uint256 maxCut) {

        // Return the glue fee range
        return (MinGlueFee, MaxGlueFee);
    }

    /**
    * @notice Retrieves the current glue expansion fee range
    * @dev Provides public access to the minimum and maximum glue expansion fee values
    *
    * @return minCut The minimum glue cut from expansion fee percentage
    * @return maxCut The maximum glue cut from expansion fee percentage
    *
    * Use case: Fee distribution calculations or protocol revenue projections
    */
    function getGlueExpansionsCutRange() external pure override returns (uint256 minCut, uint256 maxCut) {

        // Return the glue expansion fee range
        return (MinGlueExpFee, MaxGlueExpFee);
    }

    /**
    * @notice Retrieves the current glue trading fee range
    * @dev Provides public access to the minimum and maximum glue trading fee values
    *
    * @return minCut The minimum glue cut from trading fee percentage
    * @return maxCut The maximum glue cut from trading fee percentage
    *
    * Use case: Fee distribution calculations or protocol revenue projections
    */
    function getGlueTradingCutRange() external pure override returns (uint256 minCut, uint256 maxCut) {

        // Return the glue trading fee range
        return (MinGlueSwapFee, MaxGlueSwapFee);
    }
}