# Trust Assumptions

> **Document Type:** Technical Specification  
> **Last Updated:** 2026-01-07  
> **Status:** Production

---

## Overview

This document defines the **explicit assumptions** the protocol makes about its environment and the **trust relationships** between system components. Understanding these assumptions is critical for security audits and deployment decisions.

---

## 1. Technical Assumptions

### 1.1 Blockchain Infrastructure

| Assumption | Description | Risk if Violated |
|------------|-------------|------------------|
| **L1 Liveness** | Ethereum mainnet/testnet remains operational | Bids cannot be submitted; deadlines may pass |
| **Consensus Security** | 51% attack is infeasible | State could be rolled back |
| **Block Timestamps** | `block.timestamp` accurate within ~15 seconds | Deadline enforcement off by seconds (acceptable for day/week scales) |

### 1.2 Cryptographic Primitives

| Assumption | Description | Risk if Violated |
|------------|-------------|------------------|
| **Keccak256 Collision Resistance** | No two inputs produce the same hash | Bid forgery possible |
| **Keccak256 Preimage Resistance** | Hash cannot be reversed to input | Bid secrecy compromised |
| **ECDSA Security** | Private keys cannot be derived from signatures | Identity impersonation |
| **BN254 Pairing Security** | ZK proofs cannot be forged | Invalid bids accepted |

### 1.3 External Dependencies

| Dependency | Assumption | Fallback |
|------------|------------|----------|
| **IPFS/Arweave** | Tender metadata remains available | Contract state valid; human readability impaired |
| **Identity Oracle** | Provides accurate entity verification | Unauthorized entities could bid (if oracle compromised) |
| **RPC Providers** | Transactions reach the mempool | Use multiple providers |

---

## 2. Economic Assumptions

| Assumption | Description | Enforcement |
|------------|-------------|-------------|
| **Rational Actors** | Participants maximize economic utility | Bond forfeiture punishes griefing |
| **Sufficient Bond** | Bond amount deters spam but allows participation | Authority sets appropriate value |
| **Gas Affordability** | Bidders can afford transaction costs | Target L2 for high-frequency use |

---

## 3. Procedural Assumptions

| Assumption | Description |
|------------|-------------|
| **Off-chain Disputes** | Legal disputes about contract execution (not procurement process) happen off-chain |
| **Specification Quality** | Authority defines fair, non-discriminatory requirements |
| **Timely Reveals** | Bidders submit reveals before `REVEAL_DEADLINE` |

---

## 4. Trust Model

### Trust Levels Defined

| Level | Description |
|-------|-------------|
| **TRUSTED** | Assumed to behave correctly |
| **PARTIAL** | Trusted for specific operations only |
| **UNTRUSTED** | Assumed adversarial; constrained by mechanism |
| **N/A** | Not applicable to this system |

### Entity Trust Matrix

| Entity | Trust Level | Trusted With | Justification |
|--------|-------------|--------------|---------------|
| **Ethereum L1** | TRUSTED | Consensus, ordering, state | Decentralized infrastructure |
| **Smart Contracts** | TRUSTED | Logic execution | Immutable, verified code |
| **Authority** | PARTIAL | Configuration, evaluation timing | Cannot access bid contents |
| **Bidders** | UNTRUSTED | Nothing | Bonds enforce behavior |
| **Oracles** | N/A | — | System designed oracle-free |

---

## 5. What We Do NOT Trust

The protocol is explicitly designed to **not require trust** in the following:

| Entity/Property | Mitigation |
|-----------------|------------|
| **Authority keeping secrets** | Commit-Reveal: bids are hash-locked |
| **Single server availability** | Decentralized blockchain storage |
| **Database admin integrity** | Immutable ledger |
| **Bidder honesty** | Economic incentives via bonding |
| **Network censorship** | Public mempool, multiple RPC endpoints |

---

## 6. Assumption Violations

> [!WARNING]
> If any assumption is violated, the following impacts may occur:

| Violated Assumption | Impact | Severity |
|--------------------|--------|----------|
| L1 consensus compromised | State rollback, double-spending | 🔴 Critical |
| Keccak256 broken | Bid forgery, secrecy loss | 🔴 Critical |
| Identity oracle compromised | Sybil attacks possible | 🟡 Medium |
| IPFS unavailable | Cannot read tender specs | 🟢 Low |
| Authority malicious | Unfair spec design (out of scope) | ⚪ Accepted |

---

## Related Documents

- [Threat Model](../security/threat-model.md) — Attack vectors and mitigations
- [State Machine](./state-machine.md) — Lifecycle and invariants
