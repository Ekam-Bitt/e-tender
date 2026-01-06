# Protocol Summary: Decentralized E-Tendering

## The Problem
High-value procurement (construction, defense, supply chain) suffers from **information asymmetry**. The centralized party running the tender has privileged access to incoming bids. They can:
1.  **Leak prices** to a preferred bidder ("Last Look" advantage).
2.  **Censor** valid bids from competitors.
3.  **Alter** the outcome retroactively.

## The Solution
We built a trust-minimized protocol on Ethereum. It replaces the "Trusted Auctioneer" with a **Smart Contract**, shifting the source of truth from a database to the blockchain.

## Core Guarantees

### 1. Secrecy (Commit-Reveal)
**Guarantee**: *No one, not even the Admin, can calculate the value of a bid before the Bidding Deadline.*

**Mechanism**:
- Bidders submit `Hash(value, salt, metadata)`.
- The smart contract stores only the hash (32 bytes).
- After the deadline, bidders submit the raw values + salt.
- The contract verifies `Hash(raw) == storedHash`.
- **Result**: Perfect secrecy during the bidding window.

### 2. Fairness (MEV Resistance)
**Guarantee**: *An observer cannot copy a transaction to submit an identical bid to win a tie.*

**Mechanism**:
- The hash includes a `salt` (secret random number) known only to the bidder.
- If an attacker copies the `commitment`, they do not know the `salt`.
- They cannot reveal the bid later, meaning their copied commitment is useless (and they lose gas/bond).

### 3. Solvency (Bonding)
**Guarantee**: *Spam is economically irrational.*

**Mechanism**:
- Every bid requires a strict ETH deposit ("Bid Bond").
- If a bidder submits a hash but fails to reveal (DOS attack), they **forfeit the bond**.
- This creates partial solvency: the protocol is always solvent for the *winning* amount or compensates via slashed bonds.

### 4. Integrity (Immutable Audit)
**Guarantee**: *Every state change is final and auditable.*

**Mechanism**:
- A dedicated `ComplianceModule` emits specific regulatory events (`REG_BID_SUBMITTED`, etc.).
- Even if the Admin uses their "Emergency Pause" power, that action is recorded on-chain immutable history.
- Dispute Resolution allows anyone to challenge a result if they can prove (via merkle proof) that the calculation was wrong (Optimistic verification).

## Design Philosophy
We chose **Composition over Inheritance** for logic:
- **Identity**: Decoupled. We can switch from "Government ID" to "Zero-Knowledge Anon ID" just by changing the `IIdentityVerifier` address.
- **Evaluation**: Decoupled. We can switch from "Lowest Price" to "Weighted Matrix" by changing the `IEvaluationStrategy`.

This architecture ensures the protocol can evolve without monolithic upgrades.
