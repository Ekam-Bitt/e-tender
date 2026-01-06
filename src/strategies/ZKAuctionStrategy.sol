// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IEvaluationStrategy.sol";
import "../crypto/ZKRangeVerifier.sol";

/**
 * @title ZKAuctionStrategy
 * @notice Evaluation strategy that enforces bids are within a valid range using ZK proofs.
 * @dev Validates the proof during `scoreBid`.
 */
contract ZKAuctionStrategy is IEvaluationStrategy {
    
    ZKRangeVerifier public verifier;
    uint256 public minBid;
    uint256 public maxBid;

    constructor(address _verifier, uint256 _min, uint256 _max) {
        verifier = ZKRangeVerifier(_verifier);
        minBid = _min;
        maxBid = _max;
    }

    function scoreBid(uint256 _amount, bytes calldata _metadata) external view override returns (uint256) {
        // Metadata is expected to contain the ZK Proof
        // Format: [ProofBytes] (Simplified)
        
        // In this strategy, the "amount" revealed on-chain might be 0 if fully private?
        // OR, we are just proving that the revealed amount is valid?
        // Let's assume this strategy enforces Ranged Bids for a standard auction.
        
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = minBid;
        inputs[1] = maxBid;
        // In a real ZK scheme, we might pass the commitment here, not the amount?
        // But IEvaluationStrategy passes `_amount`.
        inputs[2] = _amount; // Using amount as public input for mock.

        bool valid = verifier.verifyProof(_metadata, inputs);
        require(valid, "Invalid ZK Proof");
        
        return _amount;
    }

    function isLowerBetter() external pure override returns (bool) {
        return false; // Standard Auction (Highest Bid wins)
    }
}
