# Phase 4: Code Explanation

## 1. `src/interfaces/IEvaluationStrategy.sol`
- `scoreBid`: Takes amount and metadata, returns a `uint256` score.
- `isLowerBetter`: Defines sorting direction.

## 2. `src/strategies/WeightedScoreStrategy.sol`
- Implements a "Cost Score" (Penalty Model).
- `Score = (Price * P_w) + (Delivery * D_w) + (MaxCompliance - Compliance) * C_w`.
- Ensures that a High Price, Long Delivery, or Low Compliance results in a HIGHER (worse) score.
- **Safety**: returns `type(uint256).max` if metadata is invalid, practically disqualifying the bid.

## 3. `src/Tender.sol` Refactor
- **State**: Stores `IEvaluationStrategy public evaluationStrategy`.
- **Struct**: `Bid` now tracks `uint256 score`.
- **revealBid**:
    - Takes `bytes _metadata` (Preimage).
    - Hashes it: `metadataHash = keccak256(_metadata)`.
    - Verification: Reconstructs `structHash` using `amount`, `salt`, and `metadataHash` to verify against the stored `commitment`.
    - Calls `strategy.scoreBid`.
- **evaluate**:
    - Iterates bids and finds the best score based on `strategy.isLowerBetter()`.
    - **Note**: This is an O(N) operation, suitable for typical tender sizes but not unbounded sets.

## 4. `test/Strategies.t.sol`
- Unit tests for the specific logic of the scoring algorithms.
