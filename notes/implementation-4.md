# Phase 4: Automated Evaluation Engine

## Goal
Remove human discretion from the tender evaluation process by introducing immutable, on-chain evaluation strategies.

## User Requirements
- **Objective Scoring**: Weights for Price, Delivery, Compliance.
- **Architecture**: Support On-chain scoring (simple/complex) and future Off-chain computation.
- **Integrity**: Hash-locked logic (Strategy pattern).

## Proposed Architecture

### 1. `IEvaluationStrategy` Interface
A standard interface for calculating a bid's score.
```solidity
interface IEvaluationStrategy {
    // Calculates score based on revealed data
    function scoreBid(uint256 amount, bytes calldata metadata) external view returns (uint256 score);
    
    // Returns sorting direction (True = Higher is better? False = Lower is better?)
    function isLowerBetter() external view returns (bool);
}
```

### 2. Strategy Implementations

#### `LowestPriceStrategy.sol` (Default)
- **Logic**: Returns `amount`.
- **Direction**: Lower is better.
- **Metadata**: Ignored.

#### `WeightedScoreStrategy.sol` (Complex)
- **Config**: Stored immutable weights (PriceWeight, DeliveryWeight, ComplianceWeight).
- **Metadata**: Expects ABI-encoded `(uint256 deliveryTime, uint256 complianceScore)`.
- **Logic**: `Score = Compliance(0-100) * W_c - (Price * W_p) - (Delivery * W_d)` (Simplified linear scoring).
- **Direction**: Higher is better.

### 3. `Tender.sol` Refactor

#### State
- `IEvaluationStrategy public strategy;`
- `mapping(bytes32 => uint256) public bidScores;`

#### `revealBid` Update
- **Signature**: `revealBid(uint256 _amount, bytes32 _salt, bytes calldata _metadata)`
- **Logic**:
    1. Validate `keccak256(_metadata) == _metadataHash`.
    2. Check Commitment (EIP-712).
    3. Calculate score: `strategy.scoreBid(_amount, _metadata)`.
    4. Store score.

#### `evaluate` Update
- Iterates through bids.
- Compares scores using `strategy.isLowerBetter()`.
- Sets winner.

## Verification Plan
- **TestStrategies.t.sol**: Unit test the scoring logic.
- **TestTenderEvaluation.t.sol**: Test the workflow with different strategies.
