// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IEvaluationStrategy } from "../interfaces/IEvaluationStrategy.sol";

/**
 * @title WeightedScoreStrategy
 * @author e-Tender Protocol
 * @notice Multi-criteria evaluation strategy for tenders requiring non-price factors.
 *
 * @dev This is an OPTIONAL strategy for use cases where lowest-price-only evaluation
 *      is insufficient. Common in government/enterprise tenders requiring:
 *      - Technical capability assessment
 *      - Delivery timeline commitments
 *      - Compliance/certification scores
 *
 * ## Scoring Model
 *
 * Uses a Linear Penalty Model where LOWER score = BETTER bid:
 *
 *   Score = (Price × PriceWeight) + (Delivery × DeliveryWeight) + ((MaxCompliance - Compliance) × ComplianceWeight)
 *
 * This ensures all terms are positive (no underflow risk) and:
 * - Higher Price → Higher Score (worse)
 * - Longer Delivery → Higher Score (worse)
 * - Higher Compliance → Lower Score (better)
 *
 * ## Usage Example
 *
 * ```solidity
 * // Deploy with weights: Price=1, Delivery=2, Compliance=5
 * WeightedScoreStrategy strategy = new WeightedScoreStrategy(1, 2, 5);
 *
 * // Bidder submits: Price=100 ETH, Delivery=30 days, Compliance=85%
 * bytes memory metadata = abi.encode(uint256(30), uint256(85));
 * uint256 score = strategy.scoreBid(100 ether, metadata);
 * // Score = 100 + 60 + 75 = 235 (lower wins)
 * ```
 *
 * ## Metadata Format
 *
 * `abi.encode(uint256 deliveryTime, uint256 complianceScore)`
 * - deliveryTime: Time units (days, hours, etc.) - lower is better
 * - complianceScore: 0-100 scale - higher is better
 */
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ITenderHelper } from "../interfaces/ITenderHelper.sol";
import { TenderConstants } from "../libraries/TenderConstants.sol";

contract WeightedScoreStrategy is IEvaluationStrategy {
    // bytes32 constant BID_TYPEHASH = ...; // Use TenderConstants

    uint256 public immutable PRICE_WEIGHT;
    uint256 public immutable DELIVERY_WEIGHT;
    uint256 public immutable COMPLIANCE_WEIGHT;

    // Max Compliance Score expected in metadata (e.g. 100)
    uint256 public constant MAX_COMPLIANCE = 100;

    constructor(uint256 _priceWeight, uint256 _deliveryWeight, uint256 _complianceWeight) {
        PRICE_WEIGHT = _priceWeight;
        DELIVERY_WEIGHT = _deliveryWeight;
        COMPLIANCE_WEIGHT = _complianceWeight;
    }

    /**
     * @notice Metadata expected: abi.encode(uint256 deliveryTime, uint256 complianceScore)
     */
    function verifyAndScoreBid(
        bytes32 commitment,
        uint256 amount,
        bytes32 salt,
        bytes calldata metadata,
        address /*bidder*/
    )
        external
        view
        override
        returns (uint256)
    {
        // 1. Verification
        bytes32 metadataHash = keccak256(metadata);
        bytes32 structHash = keccak256(abi.encode(TenderConstants.BID_TYPEHASH, amount, salt, metadataHash));
        bytes32 domainSeparator = ITenderHelper(msg.sender).getDomainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
        require(digest == commitment, "Invalid Commitment");

        // 2. Scoring
        if (metadata.length < 64) {
            return type(uint256).max;
        }

        (uint256 deliveryTime, uint256 complianceScore) = abi.decode(metadata, (uint256, uint256));

        if (complianceScore > MAX_COMPLIANCE) {
            complianceScore = MAX_COMPLIANCE;
        }

        uint256 pricePenalty = amount * PRICE_WEIGHT;
        uint256 deliveryPenalty = deliveryTime * DELIVERY_WEIGHT;
        uint256 compliancePenalty = (MAX_COMPLIANCE - complianceScore) * COMPLIANCE_WEIGHT;

        return pricePenalty + deliveryPenalty + compliancePenalty;
    }

    /// @inheritdoc IEvaluationStrategy
    function isLowerBetter() external pure override returns (bool) {
        return true;
    }
}
