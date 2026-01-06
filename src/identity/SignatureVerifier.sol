// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IIdentityVerifier } from "../interfaces/IIdentityVerifier.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SignatureVerifier
 * @notice Verifies identities based on signatures from a trusted Issuer.
 * @dev Simulates "Verifiable Credential" where an off-chain Issuer signs the user's address.
 *
 * TRUST MODEL:
 * This verifier assumes a trusted issuer enforcing uniqueness off-chain.
 * On-chain logic enforces authorization, not uniqueness guarantees.
 *
 * BLACKLIST SCOPE:
 * Blacklisting is identity-layer scoped, not tender-scoped.
 * Blacklisting affects all tenders using this verifier.
 */
contract SignatureVerifier is IIdentityVerifier, Ownable {
    using ECDSA for bytes32;

    address public issuer;
    mapping(address => bool) public blacklist;

    event IssuerUpdated(address newIssuer);
    event BlacklistUpdated(address user, bool status);

    error InvalidSignature();
    error UserBlacklisted();

    constructor(address _issuer) Ownable(msg.sender) {
        issuer = _issuer;
    }

    function setIssuer(address _issuer) external onlyOwner {
        issuer = _issuer;
        emit IssuerUpdated(_issuer);
    }

    function setBlacklist(address _user, bool _status) external onlyOwner {
        blacklist[_user] = _status;
        emit BlacklistUpdated(_user, _status);
    }

    /**
     * @notice Verifies that the 'proof' is a signature by the 'issuer' over the public signal (user address).
     * @param proof The signature (r, s, v).
     * @param publicSignals Array where index 0 is the user address (as bytes32).
     */
    function verify(bytes calldata proof, bytes32[] calldata publicSignals) external view override returns (bool) {
        if (publicSignals.length < 1) return false;

        address user = address(uint160(uint256(publicSignals[0])));

        if (blacklist[user]) revert UserBlacklisted();

        // Reconstruct message: Keccak256(user)
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        address signer = ethSignedMessageHash.recover(proof);

        if (signer != issuer) revert InvalidSignature();

        return true;
    }

    /// @inheritdoc IIdentityVerifier
    function identityType() external pure override returns (bytes32) {
        return "ISSUER_SIGNATURE";
    }
}
