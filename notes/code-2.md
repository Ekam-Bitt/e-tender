# Phase 2: Code Explanation

## 1. `src/Tender.sol` (Updated)

### EIP-712 Integration
Inherited `EIP712("Tender", "1")` from OpenZeppelin.
- **`BID_TYPEHASH`**: Defined as `keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)")`.
- **`revealBid`**:
    - Reconstructs the `structHash`.
    - Calls `_hashTypedDataV4(structHash)` to get the EIP-712 digest.
    - Compares this digest with the stored `commitment`.
- **`getDomainSeparator`**: Added to expose internal `_domainSeparatorV4()` for testing and frontend verification.

### Slashing Logic
- **`withdrawBond`**:
    - checks `if (!bid.revealed) revert BondForfeited();`.
    - This ensures users MUST reveal to get their money back (incentive compatibility).
- **`claimSlashedFunds`**:
    - Iterates over bidders.
    - If `!revealed` and `!winner` (and has deposit), transfers funds to Authority.

## 2. `test/Tender.t.sol` (Updated)

- **`getCommitment` Helper**:
    - Uses `MessageHashUtils.toTypedDataHash(tender.getDomainSeparator(), structHash)` to confusingly replicate the on-chain hashing logic in the test environment.
    - **Crucial Fix**: This helper calls an external function on `Tender`. In Foundry, this consumes `vm.prank`. We moved calls to this helper *before* any `vm.prank` to avoid `msg.sender` confusion.

- **`testSlashingForNonReveal`**:
    - Simulates two bidders: one reveals, one doesn't.
    - Verifies the non-revealer triggers `BondForfeited` when trying to withdraw.
    - Verifies Authority balance increases by the slashed amount.
