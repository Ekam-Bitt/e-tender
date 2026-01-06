// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IEvaluationStrategy } from "../interfaces/IEvaluationStrategy.sol";

/**
 * @title LowestPriceStrategy
 * @notice Simple strategy where the score is the bid amount, and lower is better.
 */
contract LowestPriceStrategy is IEvaluationStrategy {
    /// @inheritdoc IEvaluationStrategy
    function scoreBid(
        uint256 amount,
        bytes calldata /* metadata */
    )
        external
        pure
        override
        returns (uint256)
    {
        // Score is simply the price.
        return amount;
    }

    /// @inheritdoc IEvaluationStrategy
    function isLowerBetter() external pure override returns (bool) {
        // Lowest price wins.
        return true;
    }
}
