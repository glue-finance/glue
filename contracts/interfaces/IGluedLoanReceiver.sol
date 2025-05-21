// SPDX-License-Identifier: BUSL-1.1
// https://github.com/glue-finance/glue/blob/main/LICENCE.txt

/**

 ██████╗ ██╗     ██╗   ██╗███████╗██████╗ ██╗      ██████╗  █████╗ ███╗   ██╗
██╔════╝ ██║     ██║   ██║██╔════╝██╔══██╗██║     ██╔═══██╗██╔══██╗████╗  ██║
██║  ███╗██║     ██║   ██║█████╗  ██║  ██║██║     ██║   ██║███████║██╔██╗ ██║
██║   ██║██║     ██║   ██║██╔══╝  ██║  ██║██║     ██║   ██║██╔══██║██║╚██╗██║
╚██████╔╝███████╗╚██████╔╝███████╗██████╔╝███████╗╚██████╔╝██║  ██║██║ ╚████║
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
██████╗ ███████╗ ██████╗███████╗██╗██╗   ██╗███████╗██████╗                  
██╔══██╗██╔════╝██╔════╝██╔════╝██║██║   ██║██╔════╝██╔══██╗                 
██████╔╝█████╗  ██║     █████╗  ██║██║   ██║█████╗  ██████╔╝                 
██╔══██╗██╔══╝  ██║     ██╔══╝  ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗                 
██║  ██║███████╗╚██████╗███████╗██║ ╚████╔╝ ███████╗██║  ██║                 
╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝                 
██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗       
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝       
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗         
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝         
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗       
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝       

 */
pragma solidity ^0.8.28;

/**
 * @title IGluedLoanReceiver
 * @author BasedToschi
 * @notice Interface that must be implemented by contracts receiving glued loans from the Glue Protocol
 * @dev This interface standardizes the callback mechanism used by the Glue Protocol's flash loan feature,
 * allowing seamless integration with DeFi protocols and custom applications
 */
interface IGluedLoanReceiver {
    /**
     * @notice Executes custom logic after receiving a flash loan from the Glue Protocol
     * @dev This function is called by the protocol after transferring borrowed assets to the receiver contract
     * The receiver must ensure that the borrowed assets plus fees are returned to the glue contracts before this
     * function completes execution, otherwise the transaction will revert
     * 
     * @param glues Array of glue contract addresses that provided the loaned assets
     * @param collateral Address of the borrowed token (address(0) for ETH)
     * @param expectedAmounts Array of amounts expected to be repaid to each glue contract
     * @param params Arbitrary data passed by the loan initiator for custom execution
     * @return loanSuccess Boolean indicating whether the operation was successful
     * 
     * Use cases:
     * - Flash Loans across multiple glues
     * - Capital-efficient arbitrage across DEXes
     * - Liquidation operations in lending protocols
     * - Complex cross-protocol interactions requiring upfront capital
     * - Temporary liquidity for atomic multi-step operations
     * - Collateral swaps without requiring pre-owned capital
     */
    function executeOperation(
        address[] memory glues,
        address collateral,
        uint256[] memory expectedAmounts,
        bytes memory params
    ) external returns (bool loanSuccess);
}