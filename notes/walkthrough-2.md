# Phase 2: Sealed Bidding Walkthrough

## Overview
Phase 2 focused on strengthening the "Sealed Bid" mechanism using EIP-712 typed structural hashing and introducing economic penalties (slashing) for non-cooperative behavior.

## Deliverables
1. **[Tender.sol](../src/Tender.sol)**: Updated with EIP-712 inheritance and hashing logic.
2. **[Tender.t.sol](../test/Tender.t.sol)**: Updated tests covering EIP-712 verification and slashing scenarios.

## Key Enhancements
### 1. EIP-712 Hashing
- **Previous**: `keccak256(abi.encodePacked(amount, salt))` - Simple opaque hash.
- **New**: `_hashTypedDataV4(keccak256(abi.encode(BID_TYPEHASH, amount, salt, metadataHash)))`.
- **Benefit**: Standardized signing/hashing format. Prevents replay across different chains (chainID included) or different contracts (verifying contract address included). Included `metadataHash` to bind off-chain documents to the on-chain bid.

### 2. Stake Slashing
- **Objective**: Prevent "Option Bidding" (where a bidder submits a bid but refuses to reveal if they realize they won't win or want to disrupt).
- **Mechanism**:
    - Bidders must deposit `bidBond`.
    - `withdrawBond()` ONLY works if `revealed == true` (unless canceled).
    - If a user fails to reveal by `revealDeadline`, their bond is forfeited.
    - `claimSlashedFunds()` allows the Authority to sweep these forfeited bonds.

## Verification Results
Ran `forge test`:
- `testSubmitBid`: Verified `getCommitment` logic (EIP-712 digest generation).
- `testSlashingForNonReveal`: Verified that a non-revealing bidder CANNOT withdraw, and Authority CAN claim the funds.
- `testFullLifecycle`: Regressed full flow with new hashing scheme.

All 5 tests passed.
