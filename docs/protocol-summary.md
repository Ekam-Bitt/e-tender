# Protocol Summary

> **Document Type:** Technical Overview  
> **Audience:** Developers, Auditors, Stakeholders  
> **Last Updated:** 2026-01-07

---

## The Problem

High-value procurement (construction, defense, supply chain) suffers from **information asymmetry**. Centralized auctioneers have privileged access to incoming bids and can:

| Attack | Description |
|--------|-------------|
| **Last Look** | Leak prices to a preferred bidder |
| **Censorship** | Block valid bids from competitors |
| **Retroactive Editing** | Alter outcomes after submission |

**Impact:** Billions in losses annually due to procurement fraud and bid rigging.

---

## The Solution

A **trust-minimized protocol on Ethereum** that replaces the trusted auctioneer with a smart contract. The source of truth shifts from a private database to the blockchain.

```
┌──────────────────────────────────────────────────────────────────┐
│                    Traditional System                            │
│  Bidder ──▸ [Trusted Auctioneer] ──▸ Winner                      │
│                      │                                           │
│              Can leak, censor, alter                             │
└──────────────────────────────────────────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Decentralized System                          │
│  Bidder ──▸ [Smart Contract] ──▸ Winner                          │
│                      │                                           │
│              Immutable, transparent, auditable                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Core Guarantees

### 1. Secrecy (Commit-Reveal)

> **Guarantee:** No one—not even the Admin—can determine bid values before the deadline.

**Mechanism:**

```
1. COMMIT: Bidder submits Hash(value, salt, metadata)
2. STORE:  Contract stores only the 32-byte hash
3. WAIT:   Bidding deadline passes
4. REVEAL: Bidder submits raw value + salt
5. VERIFY: Contract checks Hash(raw) == storedHash
```

**Result:** Perfect bid secrecy during the bidding window.

---

### 2. Fairness (MEV Resistance)

> **Guarantee:** Observers cannot copy transactions to submit identical bids.

**Mechanism:**

| Step | Protection |
|------|------------|
| Hash includes secret `salt` | Attacker doesn't know the salt |
| Copied commitment is useless | Cannot reveal without salt |
| Failed reveal forfeits bond | Economic disincentive |

---

### 3. Solvency (Bonding)

> **Guarantee:** Spam and griefing are economically irrational.

**Mechanism:**

| Requirement | Enforcement |
|-------------|-------------|
| Every bid requires ETH deposit | `msg.value >= BID_BOND_AMOUNT` |
| Failure to reveal forfeits bond | `bondForfeited[bidder] = true` |
| Partial solvency guaranteed | Winner amount covered by bonds |

---

### 4. Integrity (Immutable Audit)

> **Guarantee:** Every state change is final and auditable.

**Mechanism:**

| Component | Function |
|-----------|----------|
| `ComplianceModule` | Emits regulatory events |
| Event types | `REG_BID_SUBMITTED`, `REG_BID_REVEALED`, etc. |
| Emergency actions | Recorded on-chain even if paused |
| Dispute resolution | Merkle proofs for calculation verification |

---

## Design Philosophy

### Composition Over Inheritance

The protocol uses **pluggable interfaces** for maximum flexibility:

| Interface | Purpose | Implementations |
|-----------|---------|-----------------|
| `IIdentityVerifier` | Entity authorization | `SignatureVerifier`, `ZKNullifierVerifier` |
| `IEvaluationStrategy` | Bid scoring | `LowestPriceStrategy`, `ZKAuctionStrategy` |
| `ICrossChainAdapter` | Multi-chain support | `LayerZeroBridge` (future) |

**Benefits:**
- Swap identity systems without core changes
- Switch evaluation logic per tender type
- Upgrade components independently

---

## Protocol Flow

```
┌─────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Bidder  │     │  Smart Contract  │     │   Blockchain    │
└────┬────┘     └────────┬─────────┘     └────────┬────────┘
     │                   │                        │
     │  1. Commit bid    │                        │
     │──────────────────▶│  Store hash            │
     │                   │───────────────────────▶│
     │                   │                        │
     │         Wait for bidding deadline          │
     │                   │                        │
     │  2. Reveal bid    │                        │
     │──────────────────▶│  Verify hash match     │
     │                   │───────────────────────▶│
     │                   │                        │
     │  3. ZK Proof      │                        │
     │──────────────────▶│  Verify range proof    │
     │                   │───────────────────────▶│
     │                   │                        │
     │                   │  4. Evaluate & Award   │
     │◀──────────────────│───────────────────────▶│
     │                   │                        │
```

---

## Security Boundaries

| Protected | Not Protected |
|-----------|---------------|
| Bid secrecy until reveal | Off-chain collusion |
| Process integrity | Specification fairness |
| Immutable audit trail | Key compromise |
| Valid bid filtering | L1 consensus failures |

---

## Related Documents

- [State Machine](specs/state-machine.md) — Detailed lifecycle
- [Threat Model](security/threat-model.md) — Security analysis
- [Trust Assumptions](specs/assumptions_trust.md) — Dependencies
- [ZK Integration](../ZK_INTEGRATION.md) — Proof system
