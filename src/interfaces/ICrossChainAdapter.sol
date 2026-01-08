// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICrossChainAdapter
 * @notice Interface for cross-chain bid submission
 * @dev Implementations can use CCIP, LayerZero, Hyperlane, etc.
 */
interface ICrossChainAdapter {
    // ============ Events ============

    /// @notice Emitted when a bid is received from another chain
    event CrossChainBidReceived(
        uint64 indexed sourceChainSelector,
        address indexed sourceSender,
        bytes32 indexed commitment,
        bytes32 bidderId
    );

    /// @notice Emitted when a bid is sent to another chain
    event CrossChainBidSent(
        uint64 indexed destChainSelector,
        address indexed destTender,
        bytes32 indexed commitment,
        bytes32 messageId
    );

    // ============ Errors ============

    error InvalidSourceChain(uint64 chainSelector);
    error InvalidSourceSender(address sender);
    error InsufficientFee(uint256 required, uint256 provided);
    error MessageDecodingFailed();

    // ============ Sending Functions ============

    /**
     * @notice Estimate fee for sending a cross-chain bid
     * @param destChainSelector The CCIP chain selector for destination
     * @param destTender The Tender contract address on destination chain
     * @param commitment The bid commitment hash
     * @return fee The estimated fee in native tokens
     */
    function estimateFee(
        uint64 destChainSelector,
        address destTender,
        bytes32 commitment
    ) external view returns (uint256 fee);

    /**
     * @notice Send a bid commitment to a Tender on another chain
     * @param destChainSelector The CCIP chain selector for destination
     * @param destTender The Tender contract address on destination chain
     * @param commitment The bid commitment hash
     * @return messageId The CCIP message ID for tracking
     */
    function sendBid(
        uint64 destChainSelector,
        address destTender,
        bytes32 commitment
    ) external payable returns (bytes32 messageId);

    // ============ Receiving Functions ============

    /**
     * @notice Process a received cross-chain bid
     * @dev Called by the bridge/router contract
     * @param sourceChainSelector The source chain selector
     * @param sourceSender The sender address on source chain
     * @param payload Encoded bid data
     */
    function receiveMessage(
        uint64 sourceChainSelector,
        address sourceSender,
        bytes calldata payload
    ) external;
}
