# Phase 0: Deliverable Explanation

This phase produced markdown documentation rather than executable code. Here is an explanation of the files created:

## 1. Threat Model (`/threat-model/threat-model.md`)
This document is the security bible for the project. It uses a standard format to define:
- **Actors**: Who interacts with the system.
- **Assets**: What we are protecting (Bid Secrecy, System Integrity).
- **Adversaries**: Who is trying to break it.
- **Mitigations**: How we stop them.

**Key Insight**: The decision to use a Commit-Reveal scheme came directly from the threat model analysis of "Bid Secrecy Leaks" where a trusted third party cannot be relied upon.

## 2. State Machine (`/specs/state-machine.md`)
This defines the valid states of the `Tender` contract.
- It includes a Mermaid diagram for visual verification.
- It lists "Invariants" (rules that must ALWAYS be true, e.g., "Reveal Deadline > Bidding Deadline").

**Key Insight**: Separating the `OPEN` (Commit) and `REVEAL` phases is crucial to preventing front-running and last-minute bid sniping based on seeing other bids.

## 3. Assumptions (`/specs/assumptions_trust.md`)
This document lists the "Axioms" of our system. If these are false, the system breaks.
- Example: "Miners are honest (or at least rational)."
- Example: "Bidders are rational (won't burn money)."

**Key Insight**: Explicitly stating we do NOT trust the Authority is a major shift from Web2 procurement systems where the database admin is God.
