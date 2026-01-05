# Phase 3: Identity & Sybil Resistance Plan

## Goal Description
Implement a flexible identity layer to prevent Sybil attacks and ensure compliance. Support both explicit Verifiable Credentials (VCs) and privacy-preserving Zero-Knowledge (ZK) proofs.

## User Review Required
- **ZK Circuit**: I will implement the *Verifier Smart Contract* interfaces and logic. I will NOT implement the off-chain ZK circuits (Circom/Halo2) in this phase as it requires a separate toolchain, but I will create a `MockVerifier` to simulate valid proofs.
- **Relayer**: Anonymous bidding typically requires a Relayer to pay gas. I will assume for now the user pays gas but their identity is hidden *protocol-wise* (or we use a mock Relayer). To keep it simple, `submitBid` will still be `msg.sender` based for now in the `SignatureVerifier` (non-anon), and we'll allow `msg.sender` to be decoupled in the ZK path if needed (though `Tender` currently maps `msg.sender => Bid`). *Decision: For this phase, we map `msg.sender` to Bid, so anonymity is "Identity Verifier doesn't reveal Real World ID", not "On-chain address is hidden".*

## Proposed Changes

### Interfaces
#### [NEW] [src/interfaces/IIdentityVerifier.sol](../src/interfaces/IIdentityVerifier.sol)
- `verify(address user, bytes calldata proof) returns (bool)`

### Smart Contracts
#### [NEW] [src/identity/SignatureVerifier.sol](../src/identity/SignatureVerifier.sol)
- Implements `IIdentityVerifier`.
- Checks if `proof` is a valid ECDSA signature from a trusted `ISSUER` signing `user` address.
- Used for "Verifiable Credential (issuer-signed)".

#### [NEW] [src/identity/ZKMerkleVerifier.sol](../src/identity/ZKMerkleVerifier.sol)
- Implements `IIdentityVerifier`.
- Mocks a ZK-SNARK verifier.
- Verifies that `user` is part of a Merkle Tree Root (privacy-preserving set membership).

#### [MODIFY] [src/Tender.sol](../src/Tender.sol)
- **State**: Add `IIdentityVerifier public verifier`.
- **Constructor**: Accept verifier address.
- **Modifier**: `onlyAuthenticated(bytes memory proof)`.
- **Function `submitBid`**: Accept `bytes memory identityProof`.
    - `verifier.verify(msg.sender, identityProof)`.

### Tests
#### [NEW] [test/Identity.t.sol](../test/Identity.t.sol)
- Test `SignatureVerifier` with valid/invalid signatures.
- Test `Tender` integration with specific verifiers.

## Verification Plan
- `forge test`: Ensure Identity checks pass before Bidding logic.
