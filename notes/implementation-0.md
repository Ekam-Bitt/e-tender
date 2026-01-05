# Phase 0: Problem Formalization Plan

## Goal Description
Establish a formal foundation for the blockchain-based e-tendering system. This non-coding phase focuses on defining the system architecture, threat model, state machine, and trust assumptions to ensure a secure and robust design before implementation begins.

## Proposed Changes (Documentation)

### Project Root
#### [NEW] [README.md](../README.md)
- Project overview based on the provided abstract.
- Answers to: What attacks are prevented? What attacks are accepted? Why these trade-offs?
- Directory structure explanation.

### Specs & Models
#### [NEW] [/threat-model/threat-model.md](../threat-model/threat-model.md)
- **Actors**: Authority, Bidder, Auditor, Observer.
- **Adversaries**: Malicious bidder, Colluding authority, Network-level attacker.
- **Attack Vectors**: Bid rigging, Document forgery, DoS, Sybil attacks, Collusion.
- **Mitigations**: Cryptographic commitments, Smart contract rules.

#### [NEW] [/specs/state-machine.md](../specs/state-machine.md)
- **Tender Lifecycle**: `CREATED` -> `OPEN` -> `CLOSED` -> `REVEAL_PERIOD` -> `EVALUATION` -> `AWARDED` / `CANCELED`.
- **Transitions and Invariants**: Constraints on moving between states (e.g., time checks, role permissions).
- **Mermaid Diagram**: Visual representation of the state machine.

#### [NEW] [/specs/assumptions_trust.md](../specs/assumptions_trust.md)
- **Trust Assumptions**: Ledger integrity, Oracle reliability (if any), Smart Contract correctness.
- **Explicit Assumptions**: Synchrony/Asynchrony, Key management, Regulatory compliance.
