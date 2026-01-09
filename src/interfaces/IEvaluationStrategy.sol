// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IEvaluationStrategy
 * @notice Interface for defining how tenders are scored and ranked.
 */
interface IEvaluationStrategy {
    /**
     * @notice Verifies the commitment and calculates a score for the bid.
     * @param commitment The commitment submitted by the bidder.
     * @param amount The bid amount (or 0 if hidden/ZK).
     * @param salt The salt used in commitment (or 0).
     * @param metadata Bid metadata (or ZK proof).
     * @param bidder The address of the bidder.
     * @return score The calculated score for the bid.
     */
    function verifyAndScoreBid(
        bytes32 commitment,
        uint256 amount,
        bytes32 salt,
        bytes calldata metadata,
        address bidder
    ) external view returns (uint256 score);

    /**
     * @notice Defines the sorting direction for scores.
     * @return lowerIsBetter True if a lower score is better (e.g. Lowest Price). False if higher is better.
     */
    function isLowerBetter() external view returns (bool lowerIsBetter);
}
