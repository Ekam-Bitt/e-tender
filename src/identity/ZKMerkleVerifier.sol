// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IIdentityVerifier} from "../interfaces/IIdentityVerifier.sol";
import {Halo2MerkleVerifier} from "../crypto/Halo2MerkleVerifier.sol";

/**
 * @title ZKMerkleVerifier
 * @notice ZK-SNARK Merkle Tree verifier adapter.
 * @dev Wraps the Halo2MerkleVerifier to provide a standard IdentityVerifier interface.
 */
contract ZKMerkleVerifier is IIdentityVerifier {
    bytes32 public merkleRoot;
    Halo2MerkleVerifier public verifier;

    constructor(bytes32 _merkleRoot, address _halo2Verifier) {
        merkleRoot = _merkleRoot;
        verifier = Halo2MerkleVerifier(_halo2Verifier);
    }

    /**
     * @notice Verify a ZK Merkle proof.
     * @param proof Halo2 proof bytes.
     * @param publicSignals [0] = merkleRoot, [1] = nullifier/user (unused in mock).
     */
    function verify(
        bytes calldata proof,
        bytes32[] calldata publicSignals
    ) external view override returns (bool) {
        // Enforce Structural Expectations
        require(publicSignals.length == 1, "Invalid signals length");

        // Signals: [MerkleRoot, Nullifier]
        // But IdentityVerifier interface only passes signals related to the user?
        // We need to construct the full instance array for Halo2.
        // Instances = [MerkleRoot, Nullifier]

        uint256[] memory instances = new uint256[](2);
        instances[0] = uint256(merkleRoot);
        instances[1] = uint256(publicSignals[0]); // Using signal as nullifier for now

        return verifier.verify(proof, instances);
    }

    /// @inheritdoc IIdentityVerifier
    function identityType() external pure override returns (bytes32) {
        return "ZK_MERKLE";
    }
}
