// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IEvaluationStrategy
 * @notice Interface for defining how tenders are scored and ranked.
 */
interface IEvaluationStrategy {
    /**
     * @notice Calculates the score for a bid based on its amount and revealed metadata.
     * @param amount The bid amount (e.g. price in Wei).
     * @param metadata The revealed metadata bytes (e.g. ABI encoded params).
     * @return score The calculated score.
     */
    function scoreBid(uint256 amount, bytes calldata metadata) external view returns (uint256 score);

    /**
     * @notice Defines the sorting direction for scores.
     * @return lowerIsBetter True if a lower score is better (e.g. Lowest Price). False if higher is better.
     */
    function isLowerBetter() external view returns (bool lowerIsBetter);
}
