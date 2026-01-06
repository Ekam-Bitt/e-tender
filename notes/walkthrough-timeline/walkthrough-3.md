# Phase 3: Identity & Access Control Walkthrough

## Overview
Phase 3 introduced a modular Identity Layer to prevent Sybil attacks and enforce access control. We successfully implemented a specialized Verifier pattern that decouples the identity logic from the tender logic.

## Deliverables
1. **[IIdentityVerifier.sol](../contracts/interfaces/IIdentityVerifier.sol)**: The interface ensuring flexibility.
2. **[SignatureVerifier.sol](../contracts/identity/SignatureVerifier.sol)**: A basic "Issuer-based" VC implementation.
3. **[ZKMerkleVerifier.sol](../contracts/identity/ZKMerkleVerifier.sol)**: A skeleton for privacy-preserving proofs.
4. **[Tender.sol](../contracts/Tender.sol)**: Updated to perform `verifier.verify()` on bid submission.

## Architecture Refinement (v3.2)
Based on senior verification feedback, we refined the architecture:
- **Decoupled & Domain Separated Identity**: Introduced `bidderId` hashed with `ADDR_BIDDER` domain constant.
- **Standardized Verification Interface**: Updated `IIdentityVerifier` to accept `(proof, publicSignals)` and expose `identityType()` for introspection.
- **Safety Checks**:
    - `IdentityVerificationBypassed` event emitted when using legacy/public mode.
    - `TenderOpened` event includes the `identityType` (e.g. "ISSUER_SIGNATURE", "ADDRESS", "ZK_MERKLE").

## Key Features
- **Pluggable Identity**: A Tender can use *any* contract implementing `IIdentityVerifier`.
- **Sybil Resistance**: By requiring a signature from a trusted Issuer, we prevent a single user from generating multiple identities.
- **Blacklisting**: `SignatureVerifier` includes an `Ownable` blacklist.

## Verification
- **New Tests**: `test/Identity.t.sol` covers:
    - `testAuthenticatedBid`: User with valid issuer signature can bid.
    - `testIdentityReplay`: Confirms that reusing a valid proof for a second bid reverts (Sybil resistance).
    - `testUnauthenticatedBid_Revert`: User with invalid proof is rejected.
- **Regression**: `test/Tender.t.sol` updated and passing (using `address(0)` legacy mode).
