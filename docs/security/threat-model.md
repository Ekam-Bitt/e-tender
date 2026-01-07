# Threat Model

> **Document Type:** Security Analysis  
> **Last Updated:** 2026-01-07  
> **Status:** Production

---

## Executive Summary

This document defines the security boundaries of the e-tendering protocol. It identifies **actors**, **adversaries**, **attack vectors**, and **mitigations** to provide clarity on what the system protects against—and what it explicitly does not.

---

## 1. System Overview

The e-tendering system leverages Ethereum to provide:

- **Transparency** — All actions recorded on-chain
- **Immutability** — State changes are irreversible
- **Fairness** — Rule enforcement by smart contract, not trusted parties

**Core Mechanism:** Commit-Reveal scheme using EIP-712 typed data hashing.

---

## 2. Actors and Roles

| Actor | Description | Trust Level |
|-------|-------------|-------------|
| **Authority** | Entity issuing the tender (government, corporation) | Partial — cannot access bid contents |
| **Bidder** | Entity submitting a proposal | Untrusted — constrained by bonding |
| **Auditor** | External verifier (optional) | Trusted for dispute resolution |
| **Observer** | Non-participating public entity | Read-only access |

### Capabilities Matrix

| Actor | Deploy | Configure | Submit Bid | Reveal | Evaluate | Dispute |
|-------|--------|-----------|------------|--------|----------|---------|
| Authority | ✓ | ✓ | ✗ | ✗ | ✓ | Resolve |
| Bidder | ✗ | ✗ | ✓ | ✓ | ✗ | Open |
| Auditor | ✗ | ✗ | ✗ | ✗ | ✗ | Verify |
| Observer | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

---

## 3. Adversaries

### 3.1 Malicious Bidder

**Goals:**
- Win unfairly
- Learn competitors' bids
- Disrupt the process (griefing)

**Capabilities:**
- Generate multiple addresses (Sybil attack)
- Submit invalid or spam bids
- Refuse to reveal after commitment
- Attempt front-running via mempool observation

### 3.2 Colluding Authority

**Goals:**
- Favor a specific bidder
- Leak bid information
- Censor valid bids

**Capabilities:**
- Cannot alter deployed contract logic
- Cannot decrypt committed bids (hash-based secrecy)
- Could tailor specifications (out-of-scope, governance issue)

### 3.3 Network-Level Attacker

**Goals:**
- Denial of service
- Transaction delay attacks

**Capabilities:**
- MEV/front-running bots
- Network congestion attacks
- Mempool observation

---

## 4. Attack Vectors and Mitigations

| # | Attack Vector | Severity | Mitigation |
|---|---------------|----------|------------|
| 1 | **Bid Secrecy Leak** | 🔴 Critical | Commit-Reveal: only `keccak256(amount, salt)` stored |
| 2 | **Bid Rigging / Censorship** | 🔴 Critical | Immutable blockchain; public mempool access |
| 3 | **Front-Running (MEV)** | 🟡 Medium | Salted hashes make copying useless without salt |
| 4 | **Last-Minute Sniping** | 🟡 Medium | Hard deadlines enforced by `block.timestamp` |
| 5 | **Sybil Attack** | 🟡 Medium | Bid bond requirement + Identity verification |
| 6 | **Non-Reveal Griefing** | 🟡 Medium | Bond forfeiture on failure to reveal |
| 7 | **DoS via Spam Bids** | 🟢 Low | Bond requirement makes spam economically irrational |
| 8 | **Invalid Bid Injection** | 🟢 Low | ZK range proofs reject out-of-bounds values |

---

## 5. Security Boundaries

### What the Protocol DOES Protect

| Property | Mechanism |
|----------|-----------|
| **Bid Confidentiality** | Commit-Reveal with EIP-712 |
| **Bid Integrity** | Cryptographic commitment verification |
| **Process Integrity** | State machine enforces transitions |
| **Fairness** | Uniform rules applied by smart contract |
| **Auditability** | Immutable on-chain event logs |

### What the Protocol Does NOT Protect

| Property | Reason |
|----------|--------|
| **Off-chain Collusion** | Bidders can collude outside the protocol |
| **Specification Rigging** | Authority controls tender requirements |
| **Key Compromise** | User responsibility for key security |
| **L1 Consensus Failures** | Assumed to be live and secure |

---

## 6. Trust Assumptions

| Assumption | Justification |
|------------|---------------|
| **L1 Security** | Underlying blockchain provides consensus and liveness |
| **Crypto Hardness** | Keccak256 is collision and preimage resistant |
| **Client Security** | Users protect their private keys |
| **Economic Rationality** | Actors won't burn money without gain |

---

## 7. Accepted Risks

> [!CAUTION]
> The following risks are **explicitly accepted** as out-of-scope:

| Risk | Impact | Rationale |
|------|--------|-----------|
| **Off-chain Collusion** | Cartel formation | Cannot be prevented by code |
| **Spec Rigging** | Biased requirements | Governance issue, not protocol issue |
| **Key Compromise** | Loss of funds/access | User responsibility |
| **Oracle Manipulation** | N/A | System designed to be oracle-free |

---

## 8. Severity Classification

| Level | Color | Description |
|-------|-------|-------------|
| Critical | 🔴 | Direct loss of funds or bid secrecy |
| Medium | 🟡 | Process disruption or unfair advantage |
| Low | 🟢 | Minor inconvenience, economically irrational |

---

## Related Documents

- [State Machine](../specs/state-machine.md) — Lifecycle and transitions
- [Trust Assumptions](../specs/assumptions_trust.md) — Dependency model
- [ZK Integration](../../ZK_INTEGRATION.md) — Zero-knowledge proof system
