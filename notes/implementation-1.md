# Phase 1: Core Tender Lifecycle Plan

## Goal Description
Implement the core smart contracts (`Tender.sol` and `TenderFactory.sol`) ensuring a deterministic, tamper-proof tender flow. This phase establishes the on-chain backbone using Foundry for development and testing.

## Proposed Changes

### Configuration
#### [NEW] [foundry.toml](file:///Users/ekambitt/Projects/e-tendering/foundry.toml)
- Standard Foundry configuration.
- Solc version: 0.8.20+ (Paris support).

### Smart Contracts
#### [NEW] [src/Tender.sol](file:///Users/ekambitt/Projects/e-tendering/src/Tender.sol)
- **States**: `CREATED`, `OPEN`, `SEALED`, `REVEAL`, `EVALUATED`, `AWARDED`, `FINALIZED`.
- **Structs**: `Bid` (packed), `TenderInfo`.
- **Functions**:
    - `submitBid(bytes32 _commitment)`: records bid.
    - `revealBid(uint256 _amount, bytes32 _salt)`: verifies entry.
    - `evaluate()`: selects winner.

#### [NEW] [src/TenderFactory.sol](file:///Users/ekambitt/Projects/e-tendering/src/TenderFactory.sol)
- Deploys new `Tender` contracts.
- Emits `TenderCreated` event.

### Tests
#### [NEW] [test/Tender.t.sol](file:///Users/ekambitt/Projects/e-tendering/test/Tender.t.sol)
- Unit tests for each state transition.
- Fuzzing for bid submissions and reveals.
