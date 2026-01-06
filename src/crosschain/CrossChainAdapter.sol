// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICrossChainAdapter
 * @notice Interface for Cross-Chain Interaction.
 * @dev Follows the Adapter pattern to plug into bridges like CCIP, Hyperlane, or LayerZero.
 */
interface ICrossChainAdapter {
    event BidReceived(uint64 sourceChainId, address sourceSender, bytes32 commitment);

    /**
     * @notice Receive a bid from a remote chain.
     * @dev Should be called by the Bridge contract.
     * @param sourceChainId The chain ID of the source.
     * @param sourceSender The address of the sender on source chain.
     * @param payload The encoded bid data (commitment, etc.).
     */
    function receiveRemoteBid(uint64 sourceChainId, address sourceSender, bytes calldata payload) external;

    /**
     * @notice Send a message to a remote chain (e.g., verifying a cross-chain identity).
     */
    function sendCrossChainMessage(uint64 targetChainId, address targetContract, bytes calldata message)
        external
        payable;
}
