// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ComplianceModule
 * @notice Provides a standardized audit trail for regulatory compliance.
 * @dev Emits events that are indexed by off-chain auditors.
 */
contract ComplianceModule {
    // Standard Regulatory Event Types
    bytes32 public constant REG_TENDER_CREATED = keccak256("REG_TENDER_CREATED");
    bytes32 public constant REG_BID_SUBMITTED = keccak256("REG_BID_SUBMITTED");
    bytes32 public constant REG_BID_REVEALED = keccak256("REG_BID_REVEALED");
    bytes32 public constant REG_DISPUTE_OPENED = keccak256("REG_DISPUTE_OPENED");
    bytes32 public constant REG_TENDER_FINALIZED = keccak256("REG_TENDER_FINALIZED");

    event RegulatoryLog(
        bytes32 indexed eventType,
        address indexed actor,
        bytes32 indexed entityId, // TenderID, BidderID, or DisputeID
        bytes extraData // Timestamp is implicit in block
    );

    function _logCompliance(bytes32 eventType, address actor, bytes32 entityId, bytes memory extraData) internal {
        emit RegulatoryLog(eventType, actor, entityId, extraData);
    }
}
