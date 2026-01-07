# ZK Integration Guide

## Overview

This protocol uses **zero-knowledge proofs** to verify that bid values fall within valid ranges without revealing the exact amounts. This enables sealed-bid auctions where bid validity can be cryptographically verified.

---

## Why Halo2?

| Feature | Benefit |
|---------|---------|
| **No per-circuit trusted setup** | Each new circuit doesn't require a new ceremony |
| **Universal SRS** | Uses Powers of Tau (multi-party, publicly auditable) |
| **Rust ecosystem** | Production-grade tooling and audited libraries |
| **KZG commitments** | Efficient on-chain verification via BN254 pairings |

### Comparison to Alternatives

| System | Setup | Proof Size | Verification Gas |
|--------|-------|------------|------------------|
| **Halo2 (KZG)** | Universal | ~192 bytes | ~20k |
| Groth16 | Per-circuit | ~128 bytes | ~250k |
| PLONK | Universal | ~512 bytes | ~300k |

---

## Why Range Proofs?

In sealed-bid auctions, we need to ensure:

1. **Bids are valid** - The bid amount is within `[minBid, maxBid]`
2. **Bids are secret** - The exact amount isn't revealed until the reveal phase
3. **No one can cheat** - Invalid bids are rejected cryptographically

### The Problem

Without ZK proofs, we face a dilemma:
- **Reveal amounts for validation** → Competitors see your bid
- **Don't validate amounts** → Attackers submit invalid bids

### The Solution

Range proofs prove `minBid ≤ bidValue ≤ maxBid` **without revealing `bidValue`**.

```
Prover knows:  bidValue = 50 ETH
Public inputs: minBid = 10 ETH, maxBid = 100 ETH

Proof proves:  "I know a value X where 10 ≤ X ≤ 100"
               (without revealing X = 50)
```

---

## Where ZK Fits in the Protocol

```
┌──────────────────────────────────────────────────────────────┐
│                    Tender Lifecycle                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  1. OPEN PHASE                                               │
│     └─ Bidders submit hashed commitments                     │
│                                                              │
│  2. REVEAL PHASE                                             │
│     └─ Bidders reveal values + ZK PROOFS ◄─── ZK here!       │
│             │                                                │
│             ├─ ZKRangeVerifier.verifyProof(proof, inputs)    │
│             │       │                                        │
│             │       └─ Halo2Verifier.verify() → true/false   │
│             │                                                │
│             └─ Only valid proofs are accepted                │
│                                                              │
│  3. EVALUATION PHASE                                         │
│     └─ ZKAuctionStrategy.scoreBid() → verification + scoring │
│                                                              │
│  4. AWARD PHASE                                              │
│     └─ Winner determined from verified bids only             │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## What Is NOT Proven

> ⚠️ **Critical for security understanding**

| Property | Proven? | Notes |
|----------|---------|-------|
| Value is in range | ✅ Yes | Core guarantee |
| Prover knows the value | ✅ Yes | Knowledge proof |
| Value matches committed hash | ❌ No | Handled by commit-reveal |
| Bidder is authorized | ❌ No | Handled by IdentityVerifier |
| Bid is unique per bidder | ❌ No | Handled by Tender.sol |
| Proof is fresh (not replayed) | ❌ No | Must bind to address/nonce |
| Bidder has funds | ❌ No | Handled by bond deposits |

### Security Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│  ZK PROVES                │  PROTOCOL HANDLES               │
├───────────────────────────┼─────────────────────────────────┤
│  ✓ Value in [min, max]    │  ✓ Commitment integrity         │
│  ✓ Prover knows value     │  ✓ Identity verification        │
│                           │  ✓ One-bid-per-entity           │
│                           │  ✓ Timing (deadlines)           │
│                           │  ✓ Bond/deposit management      │
└───────────────────────────┴─────────────────────────────────┘
```

---

## Integration Points

### Contracts

| Contract | Role |
|----------|------|
| `Halo2Verifier.sol` | Core cryptographic verification (BN254 pairing) |
| `ZKRangeVerifier.sol` | Adapter with public input formatting |
| `ZKAuctionStrategy.sol` | Combines verification with bid scoring |

### Off-chain

| Component | Purpose |
|-----------|---------|
| `range-proof-cli` | Generates proofs for bidders |
| `circuits/` | Halo2 circuit definition (Rust) |

---

## Future Considerations

1. **Replay Protection**: Bind proofs to `msg.sender` and nonce
2. **Circuit Audit**: Formal verification before mainnet
3. **Batch Verification**: Aggregate multiple proofs for gas savings
