// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Halo2Verifier } from "src/crypto/Halo2Verifier.sol";

/**
 * @title ZKRangeVerifier
 * @notice Adapter contract that wraps Halo2Verifier for use with ZKAuctionStrategy
 * @dev This contract adapts the standard verifier interface to the strategy interface.
 *
 * Architecture:
 *   ZKAuctionStrategy --> ZKRangeVerifier (adapter) --> Halo2Verifier (crypto)
 */
contract ZKRangeVerifier {
    // ============ State ============

    /// @notice The underlying Halo2 verifier contract
    Halo2Verifier public immutable VERIFIER;

    // ============ Events ============

    /// @notice Emitted when a proof is verified
    event ProofVerified(uint256 indexed minBid, uint256 indexed maxBid, uint256 value, bool valid);

    // ============ Errors ============

    error InvalidPublicInputCount(uint256 got, uint256 expected);

    // ============ Constructor ============

    /**
     * @notice Deploy the adapter with a reference to the Halo2Verifier
     * @param _verifier Address of the deployed Halo2Verifier contract
     */
    constructor(address _verifier) {
        require(_verifier != address(0), "ZKRangeVerifier: zero address");
        VERIFIER = Halo2Verifier(_verifier);
    }

    // ============ Verification Interface ============

    /**
     * @notice Verify a ZK range proof
     * @dev This is the interface expected by ZKAuctionStrategy
     *
     * Public Inputs Layout:
     *   [0]: min_bid - Minimum allowed bid value
     *   [1]: max_bid - Maximum allowed bid value
     *   [2]: bid_value - The bid value being proven
     *
     * The proof demonstrates that: min_bid <= bid_value <= max_bid
     * without revealing any additional information.
     *
     * @param proof The Halo2 proof bytes from the prover
     * @param publicInputs Array of [min, max, value] as uint256
     * @return valid True if the proof verifies correctly
     */
    function verifyProof(bytes calldata proof, uint256[] calldata publicInputs) external view returns (bool valid) {
        // Ensure correct number of public inputs
        if (publicInputs.length != 3) {
            revert InvalidPublicInputCount(publicInputs.length, 3);
        }

        // Delegate to the underlying Halo2 verifier
        valid = VERIFIER.verify(proof, publicInputs);

        // Revert if verification failed
        require(valid, "ZKRangeVerifier: proof verification failed");

        // Note: In a production setting, you might emit an event
        // for off-chain monitoring. Omitted here to save gas.
        // emit ProofVerified(publicInputs[0], publicInputs[1], publicInputs[2], valid);
    }

    // ============ View Functions ============

    /**
     * @notice Check if the verifier is properly configured
     * @return True if the underlying verifier is set and callable
     */
    function isConfigured() external view returns (bool) {
        return address(VERIFIER) != address(0);
    }

    /**
     * @notice Get the expected number of public inputs
     * @return The number of public inputs required (always 3)
     */
    function numPublicInputs() external pure returns (uint256) {
        return 3;
    }
}
