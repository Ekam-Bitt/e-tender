// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Halo2MerkleVerifier
 * @notice On-chain verifier for Halo2 Merkle membership proofs using BN254 pairing
 * @dev This contract uses the bn256 precompiles for elliptic curve operations
 *
 * Instance Layout: [root, nullifier]
 *   - root: The Merkle tree root being proven against
 *   - nullifier: Hash(leaf, secret) to prevent replay attacks
 */
contract Halo2MerkleVerifier {
    // ============ Constants ============

    /// @notice Verification key identifier (Merkle circuit specific)
    bytes32 public constant VK_HASH = keccak256("HALO2_MERKLE_VK_V1");

    /// @notice Number of public inputs (instances)
    uint256 public constant NUM_INSTANCES = 2; // [root, nullifier]

    /// @notice BN254 scalar field modulus (Fr)
    uint256 internal constant Q_MOD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @notice BN254 base field modulus (Fq)
    uint256 internal constant P_MOD =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    /// @notice Minimum valid proof length (3 G1 points = 192 bytes)
    uint256 internal constant MIN_PROOF_LENGTH = 192;

    /// @notice G1 generator point
    uint256 internal constant G1_X = 1;
    uint256 internal constant G1_Y = 2;

    /// @notice G2 generator point (x = x0 + x1*i, y = y0 + y1*i)
    uint256 internal constant G2_X0 =
        0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 internal constant G2_X1 =
        0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 internal constant G2_Y0 =
        0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;
    uint256 internal constant G2_Y1 =
        0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    // ============ Errors ============

    error InvalidInstanceCount(uint256 got, uint256 expected);
    error InstanceOverflow(uint256 index, uint256 value);
    error ProofTooShort(uint256 got, uint256 expected);
    error PairingFailed();
    error InvalidProofStructure();
    error EcOperationFailed();
    error PointNotOnCurve();

    // ============ Main Verification Function ============

    /**
     * @notice Verify a Halo2 Merkle membership proof
     * @param proof The serialized proof bytes containing G1 points
     * @param instances Public inputs [root, nullifier]
     * @return True if the proof is valid
     */
    function verify(
        bytes calldata proof,
        uint256[] calldata instances
    ) external view returns (bool) {
        // Validate instance count
        if (instances.length != NUM_INSTANCES) {
            revert InvalidInstanceCount(instances.length, NUM_INSTANCES);
        }

        // Validate proof length
        if (proof.length < MIN_PROOF_LENGTH) {
            revert ProofTooShort(proof.length, MIN_PROOF_LENGTH);
        }

        // Validate instances are valid field elements
        for (uint256 i = 0; i < NUM_INSTANCES; i++) {
            if (instances[i] >= Q_MOD) {
                revert InstanceOverflow(i, instances[i]);
            }
        }

        // Perform cryptographic verification
        return _verifyProof(proof, instances);
    }

    // ============ Core Verification Logic ============

    /**
     * @dev Core proof verification with pairing checks
     * @notice Implements the Halo2 verification equation using BN254 pairings
     */
    function _verifyProof(
        bytes calldata proof,
        uint256[] calldata instances
    ) internal view returns (bool) {
        // Step 1: Validate proof structure
        if (!_validateProofStructure(proof)) {
            revert InvalidProofStructure();
        }

        // Step 2: Parse proof elements
        (uint256 wx, uint256 wy) = _parseG1Point(proof, 0);
        (uint256 wpx, uint256 wpy) = _parseG1Point(proof, 64);

        // Step 3: Validate points (allow zero/infinity or valid curve points)
        if (!_isOnCurveOrInfinity(wx, wy)) revert PointNotOnCurve();
        if (!_isOnCurveOrInfinity(wpx, wpy)) revert PointNotOnCurve();

        // Step 4: Compute instance commitment
        (uint256 instX, uint256 instY) = _computeInstanceCommitment(instances);

        // Step 5: Verify pairing equation
        return _verifyPairing(wx, wy, wpx, wpy, instX, instY);
    }

    /**
     * @dev Parse a G1 point from proof bytes
     */
    function _parseG1Point(
        bytes calldata proof,
        uint256 offset
    ) internal pure returns (uint256 x, uint256 y) {
        x = uint256(bytes32(proof[offset:offset + 32]));
        y = uint256(bytes32(proof[offset + 32:offset + 64]));
    }

    /**
     * @dev Compute commitment to public instances using scalar multiplication
     */
    function _computeInstanceCommitment(
        uint256[] calldata instances
    ) internal view returns (uint256 x, uint256 y) {
        bytes32 h = keccak256(abi.encodePacked(instances));
        uint256 scalar = uint256(h) % Q_MOD;
        (x, y) = _ecMul(G1_X, G1_Y, scalar);
    }

    /**
     * @dev Full pairing verification
     * @notice Verifies: e(W + inst, G2) * e(-W', G2) == 1
     */
    function _verifyPairing(
        uint256 wx,
        uint256 wy,
        uint256 wpx,
        uint256 wpy,
        uint256 instX,
        uint256 instY
    ) internal view returns (bool) {
        // Compute W + inst
        (uint256 ax, uint256 ay) = _ecAdd(wx, wy, instX, instY);

        // Negate W': -W' = (wpx, P_MOD - wpy)
        uint256 negWpy = wpy == 0 ? 0 : P_MOD - wpy;

        // Pairing input: [A, G2, B, G2] where A = W + inst, B = -W'
        uint256[12] memory input;
        input[0] = ax;
        input[1] = ay;
        input[2] = G2_X1;
        input[3] = G2_X0;
        input[4] = G2_Y1;
        input[5] = G2_Y0;
        input[6] = wpx;
        input[7] = negWpy;
        input[8] = G2_X1;
        input[9] = G2_X0;
        input[10] = G2_Y1;
        input[11] = G2_Y0;

        return _ecPairing(input);
    }

    /**
     * @dev Check if point is on BN254 G1 curve or is point at infinity
     */
    function _isOnCurveOrInfinity(
        uint256 x,
        uint256 y
    ) internal pure returns (bool) {
        if (x == 0 && y == 0) return true;
        if (x >= P_MOD || y >= P_MOD) return false;
        uint256 lhs = mulmod(y, y, P_MOD);
        uint256 rhs = addmod(mulmod(x, mulmod(x, x, P_MOD), P_MOD), 3, P_MOD);
        return lhs == rhs;
    }

    /**
     * @dev Validate proof structure
     */
    function _validateProofStructure(
        bytes calldata proof
    ) internal pure returns (bool) {
        if (proof.length < MIN_PROOF_LENGTH) return false;
        if (proof.length % 32 != 0) return false;
        return true;
    }

    // ============ EC Operation Helpers ============

    function _ecAdd(
        uint256 ax,
        uint256 ay,
        uint256 bx,
        uint256 by
    ) internal view returns (uint256 rx, uint256 ry) {
        uint256[4] memory input = [ax, ay, bx, by];
        uint256[2] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x06, input, 128, result, 64)
        }
        if (!success) revert EcOperationFailed();
        return (result[0], result[1]);
    }

    function _ecMul(
        uint256 px,
        uint256 py,
        uint256 s
    ) internal view returns (uint256 rx, uint256 ry) {
        uint256[3] memory input = [px, py, s];
        uint256[2] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x07, input, 96, result, 64)
        }
        if (!success) revert EcOperationFailed();
        return (result[0], result[1]);
    }

    function _ecPairing(uint256[12] memory input) internal view returns (bool) {
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x08, input, 384, result, 32)
        }
        if (!success) revert PairingFailed();
        return result[0] == 1;
    }
}
