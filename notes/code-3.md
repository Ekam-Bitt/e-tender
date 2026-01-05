# Phase 3: Code Explanation

## 1. `src/interfaces/IIdentityVerifier.sol`
Updated to match ZK standards and added `function identityType() external pure returns (bytes32);` for introspection.

## 2. `src/identity/SignatureVerifier.sol`
- **Role**: Validates that an off-chain `ISSUER` has authorized the `publicSignals[0]` (User Address).
- **Refinement**: Explicit comments added defining Trust Model (Issuer enforces uniqueness).
- **Introspection**: Returns `identityType() = "ISSUER_SIGNATURE"`.

## 3. `src/Tender.sol` (Updated)
- **Bidder ID**: Bids are stored in `mapping(bytes32 => Bid) bids` using **Domain Separated Hashes**.
    - `bidderId = keccak256(abi.encodePacked("ADDR_BIDDER", identifier));`
- **Events**:
    - `TenderOpened` now emits `bytes32 identityType` ("ADDRESS" or from Verifier).
    - `IdentityVerificationBypassed` emitted if using public mode.
- **submitBid**: Logic unified to consistently hash identifiers.

## 4. `test/Identity.t.sol`
- **Replay Protection**: Added `testIdentityReplay` to prove that even with a valid Proof, a second submission attempts to write to the same `bidderId` key and reverts.
