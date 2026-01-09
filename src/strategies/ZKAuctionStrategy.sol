// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IEvaluationStrategy } from "../interfaces/IEvaluationStrategy.sol";
import { ZKRangeVerifier } from "src/crypto/ZKRangeVerifier.sol";

/**
 * @title ZKAuctionStrategy
 * @notice Evaluation strategy that enforces bids are within a valid range using ZK proofs.
 * @dev Validates the proof during `scoreBid`.
 */
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ITenderHelper } from "../interfaces/ITenderHelper.sol";
import { TenderConstants } from "../libraries/TenderConstants.sol";

contract ZKAuctionStrategy is IEvaluationStrategy {
    // bytes32 constant BID_TYPEHASH = ...; // Use TenderConstants

    uint256 public minBid;
    uint256 public maxBid;
    ZKRangeVerifier public immutable PROOF_VERIFIER;

    constructor(uint256 _min, uint256 _max, address _verifier) {
        minBid = _min;
        maxBid = _max;
        PROOF_VERIFIER = ZKRangeVerifier(_verifier);
    }

    function verifyAndScoreBid(
        bytes32 commitment,
        uint256 _amount,
        bytes32 _salt,
        bytes calldata _metadata,
        address /*_bidder*/
    )
        external
        view
        override
        returns (uint256)
    {
        // 1. Verification (EIP-712 Binding)
        // Note: Ideally ZKAuction uses ZK Commitment. But to maintain compatibility
        // with the current factory/tender setup which uses EIP-712 signatures for Intent,
        // we enforce the EIP-712 binding here.
        // A true Private ZK Auction would replace this with a Poseidon check or Proof check.
        bytes32 metadataHash = keccak256(_metadata);
        bytes32 structHash = keccak256(abi.encode(TenderConstants.BID_TYPEHASH, _amount, _salt, metadataHash));
        bytes32 domainSeparator = ITenderHelper(msg.sender).getDomainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
        require(digest == commitment, "Invalid Commitment");

        // 2. Enforce range check (Gas efficient)
        require(_amount >= minBid, "Bid too low");
        require(_amount <= maxBid, "Bid too high");

        // 3. Enforce ZK Proof check (Range)
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
