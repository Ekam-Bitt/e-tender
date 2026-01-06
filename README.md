# Decentralized E-Tendering Protocol

## Abstract
This protocol solves the problem of **corporate espionage and corruption in high-value procurement**. 

In traditional systems, trusted intermediaries (auctioneers) can leak bid prices to favored parties or censor submissions. This decentralized protocol eliminates the need for blind trust by securely handling **$10M+ tenders** entirely on-chain. It uses **Commit-Reveal Cryptography** to keep bids secret until the deadline and **Zero-Knowledge / Identity Primitives** to ensure only authorized entities participate, proving that **fairness can be mathematically enforced**.

## Architecture Overview
The system is modeled as a rigorous State Machine, ensuring that tenders move irreversibly through valid states (`Open` -> `Reveal` -> `Awarded`).
- [View State Machine Diagram](docs/specs/state-machine.md)

## Security Model
We operate under a tailored threat model that explicitly addresses specific attack vectors while acknowledging accepted risks.
- [View Threat Model](docs/security/threat-model.md)

### What attacks does this prevent?
1.  **Bid Leakage**: Competitors cannot see prices before the reveal deadline (EIP-712 Commitments).
2.  **Front-Running**: MEV bots cannot copy-cat bids due to salted hashes.
3.  **Retroactive Bidding**: No one (including Admins) can insert bids after the block time deadline.
4.  **Sybil Attacks**: Identity Verifiers ensure 1-entity-1-bid (or authorized-only).

### What attacks does it accept?
1.  **L1 DoS**: We assume the underlying chain remains live.
2.  **Collusion**: Bidders can still form off-chain cartels; the protocol ensures *process* integrity, not *social* integrity.

## Protocol Phases
The development followed a phased, industrial approach:

- **Phase 1: Core Lifecycle**: Implemented the `Tender` state machine and Factory.
- **Phase 2: Commit–Reveal**: Added EIP-712 hashing to seal bids.
- **Phase 3: Identity**: Integrated pluggable `IIdentityVerifier` for Sybil resistance.
- **Phase 4: Optimization**: Abstracted logic into `IEvaluationStrategy` (Lowest Price, Weighted Score).
- **Phase 5: Governance**: Added Dispute Resolution (Bonded Challenges) & UUPS Upgradability.
- **Phase 6: Adversarial Testing**: Validated against MEV and Timestamp attacks via simulations.

## Formal Verification & Testing
We went beyond unit tests, using **Stateless & Stateful Fuzzing** to prove system invariants.
- [View Invariant Tests](test/invariants/)

**Key Invariants Proved**:
- **Solvency**: The contract never holds less ETH than the sum of active deposits.
- **State Monotonicity**: A tender never reverts to a previous state.

## Project Structure
```
e-tendering/
├── src/           # Solidity source (core/, crypto/, strategies/, identity/)
├── test/          # Tests (unit/, integration/, invariants/)
├── script/        # Deployment scripts
├── circuits/      # ZK circuits (Rust/Halo2)
└── docs/          # Documentation (specs/, security/)
```

## Disclaimer & Trust Assumptions
This is research-grade software. While rigorously tested, it relies on specific assumptions about the underlying Identity Oracle and L1 consensus.
- [View Assumptions](docs/specs/assumptions_trust.md)

---
*Built with Foundry. Verified on Ethereum Sepolia.*

