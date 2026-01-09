// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Halo2NullifierVerifier } from "src/crypto/Halo2NullifierVerifier.sol";
import { IIdentityVerifier } from "src/interfaces/IIdentityVerifier.sol";

/**
 * @title ZKNullifierVerifier
 * @notice Adapter for Halo2NullifierVerifier to be used by Tender contract.
 * @dev Verifies that a user knows a secret to a commitment and generates a unique nullifier.
 */
contract ZKNullifierVerifier is IIdentityVerifier {
    Halo2NullifierVerifier public immutable VERIFIER;

    constructor(address _verifier) {
        VERIFIER = Halo2NullifierVerifier(_verifier);
    }

    function identityType() external pure override returns (bytes32) {
        return keccak256("NULLIFIER_V1");
    }

    /**
     * @notice Verify the Nullifier Proof
     * @param proof The zero-knowledge proof
     * @param publicSignals [commitment, nullifier, external_nullifier]
     */
    function verify(bytes calldata proof, bytes32[] calldata publicSignals) external view returns (bool) {
        require(publicSignals.length == 3, "Invalid signal count");

        uint256[] memory input = new uint256[](3);
        input[0] = uint256(publicSignals[0]); // commitment
        input[1] = uint256(publicSignals[1]); // nullifier
        input[2] = uint256(publicSignals[2]); // external_nullifier

        bool valid = VERIFIER.verify(proof, input);
        require(valid, "ZKNullifierVerifier: proof verification failed");
        return valid;
    }
}
