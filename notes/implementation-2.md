# Phase 2: Sealed Bidding Plan

## Goal Description
Enhance the core "Sealed Bid" mechanism with cryptographic best practices (EIP-712) and economic incentives (Slashing).

## User Review Required
- **Slashing Destination**: Where do slashed funds go? Plan assumes they are permanently locked or claimable by Authority. I will implement "Claimable by Authority" for now.
- **Metadata Hash**: What is `metadataHash`? Plan assumes it's a generic bytes32 (e.g., IPFS CID of specific bid documents).

## Proposed Changes

### Smart Contracts
#### [MODIFY] [src/Tender.sol](../src/Tender.sol)
- **Inheritance**: Inherit `EIP712` (from OpenZeppelin or handwritten). *Plan: Use OpenZeppelin Contract via Foundry*.
- **Structs**: Define `BidAttempt` typehash.
- **Functions**:
    - `submitBid`:
        - Input: `bytes32 commitment`.
        - Logic: Unchanged (commitment is opaque).
    - `revealBid`:
        - Input: `uint256 amount`, `bytes32 salt`, `bytes32 metadataHash`.
        - Logic: Recompute hash using `_hashTypedDataV4` or equivalent struct hash. Verify against stored commitment.
    - `withdrawBond`:
        - Logic: **Only** allow withdrawal if `revealed == true`.
    - `claimSlashedFunds` (New):
        - Logic: Authority can withdraw funds from non-revealed bids after `finalize` / `AWARDED`.

### Dependencies
- Install `openzeppelin-contracts`.

### Tests
#### [MODIFY] [test/Tender.t.sol](../test/Tender.t.sol)
- Update `testSubmitBid` and `testRevealBid` to generate valid EIP-712 hashes.
- Add `testSlashing`: Verify user cannot withdraw if they don't reveal.
- Add `testFrontRunningMitigation`: confirming nothing is visible before reveal (already covered by opaque hash, but ensuring metadata is also hidden).

## Verification Plan
- `forge test`: Ensure passing.
- Manual check of EIP-712 domain separator logic.
