// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IEvaluationStrategy } from "../interfaces/IEvaluationStrategy.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ITenderHelper } from "../interfaces/ITenderHelper.sol";
import { TenderConstants } from "../libraries/TenderConstants.sol";

/**
 * @title LowestPriceStrategy
 * @notice Simple strategy where the score is the bid amount, and lower is better.
 */
contract LowestPriceStrategy is IEvaluationStrategy {
    // bytes32 constant BID_TYPEHASH = ...; // Use TenderConstants

    /// @inheritdoc IEvaluationStrategy
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
        // 1. Reconstruct structHash
        bytes32 metadataHash = keccak256(metadata);
        bytes32 structHash = keccak256(abi.encode(TenderConstants.BID_TYPEHASH, amount, salt, metadataHash));

        // 2. Reconstruct digest using Tender's Domain Separator
        bytes32 domainSeparator = ITenderHelper(msg.sender).getDomainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);

        // 3. Verify
        require(digest == commitment, "Invalid Commitment");

        // 4. Score
        return amount;
    }

    /// @inheritdoc IEvaluationStrategy
    function isLowerBetter() external pure override returns (bool) {
        // Lowest price wins.
        return true;
    }
}
