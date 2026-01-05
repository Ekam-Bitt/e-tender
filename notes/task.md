# Tasks

- [x] Phase 0: Problem Formalization <!-- id: 0 -->
    - [x] Create directory structure <!-- id: 1 -->
    - [x] Create Threat Model Document (`/threat-model/threat-model.md`) <!-- id: 2 -->
    - [x] Create State Machine Diagram (`/specs/state-machine.md`) <!-- id: 3 -->
    - [x] Define Explicit Assumptions & Trust Model (`/specs/assumptions_trust.md`) <!-- id: 4 -->
    - [x] Create Project README (`README.md`) <!-- id: 5 -->

- [x] Phase 1: Core Tender Lifecycle (On-Chain Backbone) <!-- id: 6 -->
    - [x] Initialize Framework (Foundry) <!-- id: 7 -->
    - [x] Implement `Tender.sol` (Core Logic) <!-- id: 8 -->
    - [x] Implement `TenderFactory.sol` (Deployment) <!-- id: 9 -->
    - [x] Write Unit Tests (Foundry) <!-- id: 10 -->
    - [x] Verify Implementation against Phase 0 Specs <!-- id: 11 -->

- [x] Phase 2: Sealed Bidding (Commit–Reveal + Cryptography) <!-- id: 12 -->
    - [x] Implement EIP-712 for Commitment Hashing <!-- id: 13 -->
    - [x] Add `metadataHash` to Bid Struct and Logic <!-- id: 14 -->
    - [x] Implement Stake Slashing for Non-Reveal <!-- id: 15 -->
    - [x] Update Unit Tests for Cryptography and Slashing <!-- id: 16 -->
    - [x] Verify Attack Mitigations (Front-running, etc.) <!-- id: 17 -->

- [ ] Phase 3: Identity, Sybil Resistance & Access Control <!-- id: 18 -->
    - [x] Define `IIdentityVerifier` Interface <!-- id: 19 -->
    - [x] Implement `SignatureVerifier` (Issuer-Signed VCs) <!-- id: 20 -->
    - [x] Implement `ZKMertkleVerifier` (Mock/Skeleton for Zero-Knowledge) <!-- id: 21 -->
    - [x] Integrate Identity Verification into `Tender.sol` <!-- id: 22 -->
    - [x] Implement Governance Blacklist <!-- id: 23 -->
    - [x] Test Identity and Access Control Scenarios <!-- id: 24 -->
    - [x] Refactor: Introduce `bidderId` and decouple `msg.sender` <!-- id: 26 -->
    - [x] Refactor: Update `IIdentityVerifier` to `(proof, publicSignals)` <!-- id: 27 -->
    - [x] Refinement: Domain Separate `bidderId` <!-- id: 28 -->
    - [x] Refinement: Add Trust Model & Scope Comments <!-- id: 29 -->
    - [x] Refinement: Add ZK Safety Checks & Legacy Event <!-- id: 30 -->
    - [x] Test: Identity Replay/Reuse <!-- id: 31 -->

- [ ] Phase 4: Environment Setup & Tooling <!-- id: 28 -->
