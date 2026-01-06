// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IIdentityVerifier
 * @notice Interface for different identity verification strategies (VCs, ZK, etc.)
 */
interface IIdentityVerifier {
    /**
     * @notice Verifies if a user is authorized to participate.
     * @param proof Arbitrary bytes containing the proof (signature, ZK proof, etc.).
     * @param publicSignals Array of public inputs/signals (e.g., nullifier, root, userAddress).
     * @return valid True if verification succeeds.
     */
    function verify(
        bytes calldata proof,
        bytes32[] calldata publicSignals
    ) external view returns (bool valid);

    /**
     * @notice Returns a consistent identifier for the verification type.
     * @return typeId e.g. "ISSUER_SIGNATURE" or "ZK_NULLIFIER"
     */
    function identityType() external pure returns (bytes32 typeId);
}
