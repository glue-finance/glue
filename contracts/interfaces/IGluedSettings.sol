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
██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗  
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝  
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝

 */

pragma solidity ^0.8.28;

/**
 * @title IGluedSettings
 * @dev Interface for managing protocol configuration parameters, fee structures, and administrative controls.
 * This contract serves as the central configuration hub for the Glued protocol, allowing for
 * dynamic adjustment of fees, designation of fee recipients, and governance of protocol parameters.
 * The interface includes functions for ownership management, fee updates, address assignments,
 * and provides various status checks for protocol governance.
 */
interface IGluedSettings {

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
    function transferOwnership(address newOwner) external;

    /**
    * @notice Sets the team address that receives remaining protocol fee portion
    * @dev Only the current team address can update this to ensure secure transitions
    *
    * @param newTeamAddress The new address to receive the team's share of protocol fees
    *
    * Use case: Transitioning team treasury management or updating protocol revenue destinations
    */
    function setTeamAddress(address newTeamAddress) external;

    /**
    * @notice Sets the address that receives the main glue fee portion
    * @dev Updates the destination for glue protocol fees, impacting protocol revenue distribution
    *
    * @param newGlueFeeAddress The new address to receive the glue fee revenue share
    *
    * Use case: Redirecting protocol revenue to new treasury contracts or revenue management systems
    */
    function setGlueFeeAddress(address newGlueFeeAddress) external;

    /**
    * @notice Permanently renounces ownership of the contract
    * @dev Irreversibly sets owner to address(0), removing all governance capabilities
    *
    * Use case: Protocol decentralization milestone or transitioning to fully immutable operations
    */
    function renounceOwnership() external;

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
    function updateExpProtocolFee(uint256 newExpProtocolFee) external;

    /**
    * @notice Updates the swap protocol fee percentage
    * @dev Controls the fee applied to swap operations, bounded by min/max safety limits
    *
    * @param newSwapProtocolFee The new swap protocol fee percentage (in PRECISION units)
    *
    * Use case: Fee adjustment in response to market conditions or protocol revenue requirements
    */
    function updateSwapProtocolFee(uint256 newSwapProtocolFee) external;

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
    function updateGlueFee(uint256 newGlueFee) external;

    /** 
    * @notice Updates the glue expansions fee percentage
    * @dev Controls the fee percentage applied specifically to protocol expansion operations
    *
    * @param newGlueExpFee The new glue expansion fee percentage (in PRECISION units)
    *
    * Use case: Fine-tuning economics for protocol expansion
    */
    function updateGlueExpFee(uint256 newGlueExpFee) external;
    
    /**
    * @notice Updates the glue swap fee percentage
    * @dev Controls the fee percentage applied specifically to protocol swap operations
    *
    * @param newGlueSwapFee The new glue swap fee percentage (in PRECISION units)
    *
    * Use case: Fine-tuning economics for protocol swap operations
    */
    function updateGlueSwapFee(uint256 newGlueSwapFee) external;

    // █████╗ Granular Permissions
    // ╚════╝ The permissions that can be permanently removed to lock the protocol parameters
    
    /**
    * @notice Permanently removes the ability to modify expanded protocol fees
    * @dev Irreversibly locks the expanded protocol fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeExpProtocolFeeOwnership() external;
    
    /**
    * @notice Permanently removes the ability to modify the swap protocol fee
    * @dev Irreversibly locks the swap protocol fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeSwapProtocolFeeOwnership() external;
    
    /**
    * @notice Permanently removes the ability to change the glue fee address
    * @dev Irreversibly locks the glue fee recipient address
    *
    * Use case: Granular control over protocol parameters
    */
    function removeGlueOwnership() external;
    
    /**
    * @notice Permanently removes the ability to modify the glue fee percentage
    * @dev Irreversibly locks the glue fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeGlueFeeOwnership() external;
    
    /** 
    * @notice Permanently removes the ability to modify the glue expansion fee
    * @dev Irreversibly locks the glue expansion fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeGlueExpFeeOwnership() external;
    
    /**
    * @notice Permanently removes the ability to modify the glue swap fee
    * @dev Irreversibly locks the glue swap fee parameter
    *
    * Use case: Granular control over protocol parameters
    */
    function removeGlueSwapFeeOwnership() external;

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
    function getOwner() external view returns (address owner);

    /**
    * @notice Retrieves the current team address
    * @dev Provides public access to the address receiving the team's protocol fee share
    *
    * @return team The current team address configured to receive protocol fees
    *
    * Use case: Integration with protocol dashboards or verification of fee destinations
    */
    function getTeamAddress() external view returns (address team);
    
    /**
    * @notice Retrieves the current glue fee address
    * @dev Provides public access to the address receiving the glue portion of protocol fees
    *
    * @return glue The current glue fee address configured to receive protocol fees
    *
    * Use case: Protocol analytics, fee flow verification, or integration with monitoring systems
    */
    function getGlue() external view returns (address glue);

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
    function getExpansionsFee() external view returns (uint256 expansionsFee);
    
    /**
    * @notice Retrieves the current swap protocol fee percentage
    * @dev Provides public access to the fee rate applied to swap operations
    *
    * @return tradingFee The current swap protocol fee percentage (in PRECISION units)
    *
    * Use case: Fee calculation in swap modules or client-side fee estimations
    */
    function getTradingFee() external view returns (uint256 tradingFee);

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
    function getGlueProtocolCut() external view returns (uint256 glueProtocolCut);
    
    /**
    * @notice Retrieves the current glue expansion fee percentage
    * @dev Provides the percentage applied specifically to expansion operations
    *
    * @return glueExpansionsCut The current glue expansion fee percentage (in PRECISION units)
    *
    * Use case: Protocol expansion planning or economic impact analysis
    */
    function getGlueExpansionsCut() external view returns (uint256 glueExpansionsCut);
    
    /**
    * @notice Retrieves the current glue swap fee percentage
    * @dev Provides the percentage applied specifically to swap operations
    *
    * @return glueTradingCut The current glue swap fee percentage (in PRECISION units)
    *
    * Use case: Protocol swap planning or economic impact analysis
    */
    function getGlueTradingCut() external view returns (uint256 glueTradingCut);

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
    function getProtocolFeeInfo() external view returns (uint256 glueProtocolCut, address glue, address team);
    
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
    function getExpansionsFeeInfo() external view returns (uint256 expansionsFee, uint256 glueExpansionsCut, address glue, address team);
    
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
    function getTradingFeeInfo() external view returns (uint256 tradingFee, uint256 glueTradingCut, address glue, address team);
    
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
    function getGlueOwnershipStatus() external view returns (bool expProtocolFeeRenounced, bool swapProtocolFeeRenounced, bool glueProtocolCutRenounced, bool glueExpansionsCutRenounced, bool glueTradingCutRenounced, bool glueAddressRenounced);

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
    function getExpansionsFeeRange() external pure returns (uint256 minFee, uint256 maxFee);

    /**
    * @notice Retrieves the current swap protocol fee range
    * @dev Provides public access to the minimum and maximum swap protocol fee values
    *
    * @return minFee The minimum trading fee percentage
    * @return maxFee The maximum trading fee percentage
    *
    * Use case: Fee calculation in swap modules or client-side fee estimations
    */
    function getTradingFeeRange() external pure returns (uint256 minFee, uint256 maxFee);

    /**
    * @notice Retrieves the current glue protocol cut range
    * @dev Provides public access to the minimum and maximum glue protocol cut values
    *
    * @return minCut The minimum glue cut from protocol fee percentage
    * @return maxCut The maximum glue cut from protocol fee percentage
    *
    * Use case: Fee distribution calculations or protocol revenue projections
    */
    function getGlueProtocolCutRange() external pure returns (uint256 minCut, uint256 maxCut);

    /**
    * @notice Retrieves the current glue expansion fee range
    * @dev Provides public access to the minimum and maximum glue expansion fee values
    *
    * @return minCut The minimum glue cut from expansion fee percentage
    * @return maxCut The maximum glue cut from expansion fee percentage
    *
    * Use case: Fee distribution calculations or protocol revenue projections
    */
    function getGlueExpansionsCutRange() external pure returns (uint256 minCut, uint256 maxCut);

    /**
    * @notice Retrieves the current glue trading fee range
    * @dev Provides public access to the minimum and maximum glue trading fee values
    *
    * @return minCut The minimum glue cut from trading fee percentage
    * @return maxCut The maximum glue cut from trading fee percentage
    *
    * Use case: Fee distribution calculations or protocol revenue projections
    */
    function getGlueTradingCutRange() external pure returns (uint256 minCut, uint256 maxCut);

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
    * @dev Error thrown when the caller does not have the permission to process the request
    */
    error OwnershipNotGranted();

    /**
    * @dev Error thrown when the inputs are invalid
    */
    error InvalidInputs();
    
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
    * @dev Emitted when ownership of the contract is transferred.
    * @param previousOwner Address of the former owner.
    * @param newOwner Address of the new owner.
    */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Emitted when the team treasury address is changed.
    * @param previousTeamAddress The former team treasury address.
    * @param newTeamAddress The new team treasury address.
    */
    event TeamAddressUpdated(address indexed previousTeamAddress, address indexed newTeamAddress);

    /**
    * @dev Emitted when the Glue fee recipient address is changed.
    * @param previousGlueFeeAddress The former fee recipient address.
    * @param newGlueFeeAddress The new fee recipient address.
    */
    event GlueFeeAddressUpdated(address indexed previousGlueFeeAddress, address indexed newGlueFeeAddress);
    
    /**
    * @dev Emitted when the exponential protocol fee rate is updated.
    * @param newExpProtocolFee The new exponential protocol fee value.
    */
    event ExpProtocolFeeUpdated(uint256 newExpProtocolFee);
    
    /**
    * @dev Emitted when the swap protocol fee rate is updated.
    * @param newSwapProtocolFee The new swap protocol fee value.
    */
    event SwapProtocolFeeUpdated(uint256 newSwapProtocolFee);
    
    /**
    * @dev Emitted when the base Glue fee rate is updated.
    * @param newGlueFee The new base Glue fee value.
    */
    event GlueFeeUpdated(uint256 newGlueFee);
    
    /**
    * @dev Emitted when the exponential Glue fee rate is updated.
    * @param newGlueExpFee The new exponential Glue fee value.
    */
    event GlueExpFeeUpdated(uint256 newGlueExpFee);
    
    /**
    * @dev Emitted when the swap Glue fee rate is updated.
    * @param newGlueSwapFee The new swap Glue fee value.
    */
    event GlueSwapFeeUpdated(uint256 newGlueSwapFee);
    
    /**
    * @dev Emitted when the ability to modify exponential protocol fees is permanently removed.
    */
    event ExpProtocolFeeOwnershipRemoved();
    
    /**
    * @dev Emitted when the ability to modify swap protocol fees is permanently removed.
    */
    event SwapProtocolFeeOwnershipRemoved();
    
    /**
    * @dev Emitted when the ability to modify Glue ownership parameters is permanently removed.
    */
    event GlueOwnershipRemoved();
    
    /**
    * @dev Emitted when the ability to modify Glue fee parameters is permanently removed.
    */
    event GlueFeeOwnershipRemoved();
    
    /**
    * @dev Emitted when the ability to modify exponential Glue fee parameters is permanently removed.
    */
    event GlueExpFeeOwnershipRemoved();
    
    /**
    * @dev Emitted when the ability to modify swap Glue fee parameters is permanently removed.
    */
    event GlueSwapFeeOwnershipRemoved();
}

