# Evaluation Strategies

At deployment time, each Tender is configured with exactly one evaluation strategy.
The strategy defines how bids are validated and how a winner is selected.

---

## Available Strategies

| Strategy | Purpose | When to Use |
|----------|---------|-------------|
| **ZKAuctionStrategy** | Enforces zero-knowledge range proofs and validates bids cryptographically | Privacy-preserving, spam-resistant, anonymous tenders |
| **LowestPriceStrategy** | Selects the lowest valid bid | Simple, transparent price-only tenders |
| **WeightedScoreStrategy** | Scores bids using multiple criteria (price, delivery, compliance) | Complex procurement with qualitative factors |

---

## Strategy Details

### ZKAuctionStrategy

- **Validates bids using ZK range proofs**
- Ensures bid amounts:
  - Are within protocol-defined bounds
  - Are cryptographically tied to evaluation
- Works with:
  - `ZKRangeVerifier` (economic correctness)
  - `ZKNullifierVerifier` (anonymous uniqueness, spam resistance)
- No identity assumptions
- **Best suited for:**
  - High-value or sensitive tenders
  - Situations requiring privacy and strong correctness guarantees

> **Key property:** Cryptography directly constrains auction outcomes.

---

### LowestPriceStrategy

- Deterministic and transparent
- Winner is the bidder with the lowest revealed price
- No ZK requirements
- Minimal gas and complexity

> **Key property:** Maximum simplicity and auditability.

---

### WeightedScoreStrategy

- **Supports multi-criteria evaluation:**
  - Price
  - Delivery time
  - Compliance metadata
- Uses configurable weights
- Deterministic scoring logic

**Scoring Formula:**
```
Score = (Price × PriceWeight) + (Delivery × DeliveryWeight) + ((MaxCompliance - Compliance) × ComplianceWeight)
```

Lower score = better bid.

> **Key property:** Models real-world procurement where price alone is insufficient.

**Usage Example:**
```solidity
// Deploy with weights: Price=1, Delivery=2, Compliance=5
WeightedScoreStrategy strategy = new WeightedScoreStrategy(1, 2, 5);

// Bidder submits: Price=100, Delivery=30 days, Compliance=85%
bytes memory metadata = abi.encode(uint256(30), uint256(85));
// Note: In production, verifyAndScoreBid receives the commitment and verifies it first.
uint256 score = strategy.verifyAndScoreBid(commitment, 100, salt, metadata, bidder);
// Score = 100 + 60 + 75 + Verification Cost
```

---

## Architectural Principle

Strategies are **pluggable**. `Tender.sol` does not know how bids are evaluated.

Each strategy:
- Implements `IEvaluationStrategy`
- Encapsulates its own validation logic
- Cannot modify tender lifecycle or funds directly

This separation ensures:
- Clean extensibility
- No strategy-specific assumptions leak into the core protocol
- New strategies can be added without modifying existing tenders

---

## Contract References

| Contract | Location |
|----------|----------|
| `IEvaluationStrategy` | [`src/interfaces/IEvaluationStrategy.sol`](../src/interfaces/IEvaluationStrategy.sol) |
| `ZKAuctionStrategy` | [`src/strategies/ZKAuctionStrategy.sol`](../src/strategies/ZKAuctionStrategy.sol) |
| `LowestPriceStrategy` | [`src/strategies/LowestPriceStrategy.sol`](../src/strategies/LowestPriceStrategy.sol) |
| `WeightedScoreStrategy` | [`src/strategies/WeightedScoreStrategy.sol`](../src/strategies/WeightedScoreStrategy.sol) |
