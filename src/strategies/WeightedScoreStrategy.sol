// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IEvaluationStrategy } from "../interfaces/IEvaluationStrategy.sol";

/**
 * @title WeightedScoreStrategy
 * @notice Complex strategy that scores based on Price, Delivery Time, and Compliance.
 * @dev Formula: Score = (Compliance * complianceWeight) - (Price * priceWeight) - (Delivery * deliveryWeight) + Offset
 *      However, to avoid large negative numbers or underflows, we use a scoring model where:
 *      Score = MaxScore - (PricePenalty + DeliveryPenalty) + ComplianceBonus
 *      Lower Price/Delivery is better. Higher Compliance is better.
 *
 *      Let's use a simpler standard formula for "Points":
 *      Points = (MaxPrice / BidPrice) * PriceWeight + (MinDelivery / BidDelivery) * DeliveryWeight ...
 *      But division is tricky and we don't know Max/Min of other bids during individual scoring.
 *
 *      So, let's use a Linear Penalty Model (Lower is Better matches Price logic?):
 *      Score = (Price * priceWeight) + (Delivery * deliveryWeight) - (Compliance * complianceWeight)
 *      Here, "Score" is a "Cost Score". Lower is Better.
 *      High Price -> High Score (Bad)
 *      High Delivery -> High Score (Bad)
 *      High Compliance -> Low Score (Good)
 *
 *      We need to ensure (Compliance * complianceWeight) doesn't underflow the total.
 *      So: Score = (Price * P_w) + (Delivery * D_w) + (MaxCompliance - Compliance) * C_w.
 *      This ensures all terms are positive penalties.
 */
contract WeightedScoreStrategy is IEvaluationStrategy {
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
    function scoreBid(uint256 amount, bytes calldata metadata) external view override returns (uint256) {
        if (metadata.length < 64) {
            // Invalid metadata, return max penalty (worst score)
            return type(uint256).max;
        }

        (uint256 deliveryTime, uint256 complianceScore) = abi.decode(metadata, (uint256, uint256));

        // Cap compliance to max to prevent underflow hacks if we used subtraction directly,
        // but here we use (MAX - Compliance).
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
