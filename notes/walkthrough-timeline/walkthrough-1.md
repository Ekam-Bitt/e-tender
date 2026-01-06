# Phase 1: Core Tender Lifecycle Walkthrough

## Overview
Implemented the core on-chain logic for the E-Tendering system using Solidity and Foundry. The implementation adheres to the formal state machine defined in Phase 0.

## Deliverables
1. **[Tender.sol](../contracts/Tender.sol)**: The main state machine contract.
2. **[TenderFactory.sol](../contracts/TenderFactory.sol)**: Factory to deploy new tenders.
3. **[TenderTest.t.sol](../test/Tender.t.sol)**: Comprehensive unit tests.

## Key Features Implemented
- **Commit-Reveal Scheme**: Bidders submit `keccak256(amount, salt)` during the `OPEN` phase, ensuring bid secrecy. Matches `Bid Secrecy Leak` mitigation from Threat Model.
- **Strict State Machine**: Logic enforces `CREATED` -> `OPEN` -> `REVEAL` -> `EVALUATION` -> `AWARDED`.
- **Lazy State Transitions**: Transitions happen automatically based on `block.timestamp` checks during user interactions (read/write), saving gas on explicit "close" transactions.

## Verification Results
Ran `forge test` covering:
- ✅ Authorization checks (onlyAuthority).
- ✅ State transitions (cannot bid before open, cannot reveal before deadline).
- ✅ Bidding logic (deposits, commitments).
- ✅ Full lifecycle (Start -> Bid -> Reveal -> Winner Selection).

```bash
Ran 6 tests for test/Tender.t.sol:TenderTest
[PASS] testFullLifecycle()
[PASS] testInitialState()
[PASS] testOpenTendering()
[PASS] testRevealBid()
[PASS] testSubmitBid()
[PASS] testSubmitBidBeforeOpen_Revert()
```
