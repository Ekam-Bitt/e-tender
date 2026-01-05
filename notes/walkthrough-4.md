# Phase 4: Automated Evaluation Engine Walkthrough

## Overview
Phase 4 removed human discretion from the evaluation process by implementing an **Automated Evaluation Engine**. This ensures that the winner is determined strictly by the on-chain logic defined at tender creation.

## Deliverables
1. **[IEvaluationStrategy.sol](../src/interfaces/IEvaluationStrategy.sol)**: Interface for pluggable scoring logic.
2. **[LowestPriceStrategy.sol](../src/strategies/LowestPriceStrategy.sol)**: Standard logic (Lowest Price wins).
3. **[WeightedScoreStrategy.sol](../src/strategies/WeightedScoreStrategy.sol)**: Complex logic (Price + Delivery + Compliance weights).
4. **[Tender.sol](../src/Tender.sol)**: Refactored to delegate scoring to the Strategy.

## Key Features
- **Pluggable Strategies**: A Tender is deployed with a specific Strategy contract address.
- **Metadata Reveal**: `revealBid` now accepts `bytes calldata metadata`.
    - **Commitment Binding**: The protocol cryptographically binds **Bid Amount + Metadata + Salt** in the EIP-712 commitment. This prevents post-reveal manipulation of scoring inputs.
    - **Validation**: `keccak256(metadata)` is verified against the signed commitment before scoring.
- **Sorting**: The `evaluate` function sorts Bids based on `strategy.isLowerBetter()`.

## Security & Architecture Notes
- **Strategy Immutability**: The Evaluation Strategy is immutable per Tender instance. It cannot be upgraded or changed post-creation to ensure fairness.
- **Metadata Semantic Trust**: The protocol enforces integrity (you revealed what you committed to), but not semantic correctness (e.g. putting "0 days" delivery when impossible). Garbage-in results in Garbage-scores.
- **Scalability**: On-chain sorting is O(N). For large-scale tenders, future phases should move to Off-chain sorting with ZK verification.

## Verification
- **Test Suite**: `test/Strategies.t.sol` added.
    - Verified `LowestPriceStrategy` returns amount.
    - Verified `WeightedScoreStrategy` correctly weighs `(Price, Delivery, Compliance)` and penalizes missing metadata.
- **Regression**: `test/Tender.t.sol` passing with `LowestPriceStrategy` as default.
