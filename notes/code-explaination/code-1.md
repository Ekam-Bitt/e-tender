# Phase 1: Code Explanation

## 1. `contracts/Tender.sol`

This is the core smart contract representing a single tender.

### State Variables
- `state`: Enum tracking the current phase (`OPEN`, `REVEAL_PERIOD`, etc.).
- `bids`: Mapping from bidder address to `Bid` struct.
- `biddingDeadline` / `revealDeadline`: Timestamp boundaries.

### Key Functions

#### `submitBid(bytes32 _commitment)`
- **Phase**: `TenderState.OPEN`
- **Logic**: Accepts a hash (commitment) and a deposit. Stores it in the `bids` mapping.
- **Checks**:
    - `msg.value >= bidBondAmount`: preventing spam.
    - `block.timestamp < biddingDeadline`: enforcing time.
    - `commitment` not empty: preventing errors.

#### `revealBid(uint256 _amount, bytes32 _salt)`
- **Phase**: `TenderState.REVEAL_PERIOD`
- **Logic**: Verifies that the user knows the preimage of the commitment.
- **Verification**: `keccak256(abi.encodePacked(_amount, _salt)) == storedCommitment`.
- **Effect**: If valid, updates `revealedAmount` for the bidder.

#### `evaluate()`
- **Phase**: `TenderState.EVALUATION`
- **Logic**: Iterates through all bidders to find the lowest *revealed* bid.
- **Optimization**: Currently O(N), acceptable for a prototype or small-scale tenders. In production with thousands of bids, this would strictly need to be off-chain computed and on-chain verified (e.g., via ZK-proof or optimistic challenge).

## 2. `contracts/TenderFactory.sol`

A simple factory pattern implementation.

### Key Functions
#### `createTender(...)`
- Deploys a new instance of `Tender`.
- Why? Allows the Authority to spin up multiple distinct tenders without redeploying code manually.
- Emits `TenderContractDeployed` for the frontend/indexer (The Graph) to pick up.

## 3. `test/Tender.t.sol`

Unit tests written in Foundry (Solidity).

### Key Tests
- `testSubmitBid()`: Happy path for bidding.
- `testSubmitBidBeforeOpen_Revert()`: Verifies that you cannot bid before the authority opens the tender. Used `vm.expectRevert` to catch the custom error.
- `testFullLifecycle()`: An integration test simulating the entire flow from creation to award.
