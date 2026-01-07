// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IEvaluationStrategy} from "../interfaces/IEvaluationStrategy.sol";
import {ZKRangeVerifier} from "src/crypto/ZKRangeVerifier.sol";

/**
 * @title ZKAuctionStrategy
 * @notice Evaluation strategy that enforces bids are within a valid range using ZK proofs.
 * @dev Validates the proof during `scoreBid`.
 */
contract ZKAuctionStrategy is IEvaluationStrategy {
    uint256 public minBid;
    uint256 public maxBid;
    ZKRangeVerifier public immutable PROOF_VERIFIER;

    constructor(uint256 _min, uint256 _max, address _verifier) {
        minBid = _min;
        maxBid = _max;
        PROOF_VERIFIER = ZKRangeVerifier(_verifier);
    }

    function scoreBid(
        uint256 _amount,
        bytes calldata _metadata
    ) external view override returns (uint256) {
        // Enforce range check (Gas efficient)
        require(_amount >= minBid, "Bid too low");
        require(_amount <= maxBid, "Bid too high");

        // Enforce ZK Proof check (Cryptographic)
        // Public Inputs: [min, max, value]
        uint256[] memory publicInputs = new uint256[](3);
        publicInputs[0] = minBid;
        publicInputs[1] = maxBid;
        publicInputs[2] = _amount;

        bool valid = PROOF_VERIFIER.verifyProof(_metadata, publicInputs);
        require(valid, "Invalid ZK Proof");

        return _amount;
    }

    function isLowerBetter() external pure override returns (bool) {
        return false; // Standard Auction (Highest Bid wins)
    }
}
