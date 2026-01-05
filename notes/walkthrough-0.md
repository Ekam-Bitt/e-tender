# Phase 0: Problem Formalization Walkthrough

## Overview
Phase 0 focused on defining the theoretical and formal boundaries of the system. No code was written, but the architectural groundwork was laid to prevent logic errors in Phase 1.

## Deliverables
1. **[Threat Model](../threat-model/threat-model.md)**: Defined the security landscape.
   - Identified "Bid Secrecy Leak" as a high risk -> Mitigated by Commit-Reveal.
   - Identified "Colluding Authority" -> Mitigated by removing Authority ability to modify bids on-chain.

2. **[State Machine](../specs/state-machine.md)**: Defined the rigid lifecycle.
   - `CREATED`: Setup.
   - `OPEN`: Bidding (Commit phase).
   - `REVEAL`: Opening bids (Reveal phase).
   - `EVALAUTION`: Selecting winner.
   - `AWARDED`: Final state.

3. **[Trust Assumptions](../specs/assumptions_trust.md)**:
   - We explicitly DO NOT trust the Authority to keep secrets.
   - We trust the Ethereum blockchain for consensus and ordering.

## Conclusion
The problem space is now well-defined. The system is an "economic protocol" governed by code, not just a CRUD app.
