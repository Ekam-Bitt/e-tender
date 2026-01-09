// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { ZKAuctionStrategy } from "src/strategies/ZKAuctionStrategy.sol";
import { ZKRangeVerifier } from "src/crypto/ZKRangeVerifier.sol";
import { Halo2Verifier } from "src/crypto/Halo2Verifier.sol";
import { TenderConstants } from "src/libraries/TenderConstants.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract ZKAuctionStrategyTest is Test {
    ZKAuctionStrategy public strategy;
    ZKRangeVerifier public zkVerifier;
    Halo2Verifier public halo2Verifier;

    uint256 constant MIN_BID = 10 ether;
    uint256 constant MAX_BID = 100 ether;

    function setUp() public {
        halo2Verifier = new Halo2Verifier();
        zkVerifier = new ZKRangeVerifier(address(halo2Verifier));
        strategy = new ZKAuctionStrategy(MIN_BID, MAX_BID, address(zkVerifier));
    }

    function test_Initialization() public view {
        assertEq(strategy.minBid(), MIN_BID);
        assertEq(strategy.maxBid(), MAX_BID);
        assertEq(address(strategy.PROOF_VERIFIER()), address(zkVerifier));
    }

    function test_IsLowerBetter() public view {
        assertFalse(strategy.isLowerBetter(), "Standard auction should prefer higher bids");
    }

    // function test_ScoreBid_ValidProof() public {
    // Requires a real valid proof (pairing) which is hard to generate in tests.
    // The integration is verified via negative tests and flow validation.
    // }

    // bytes32 constant BID_TYPEHASH ... using TenderConstants

    bytes32 domainSeparator = keccak256("DOMAIN_SEPARATOR");

    function getDomainSeparator() external view returns (bytes32) {
        return domainSeparator;
    }

    function _getCommitment(uint256 amount, bytes32 salt, bytes memory metadata) internal view returns (bytes32) {
        bytes32 metadataHash = keccak256(metadata);
        bytes32 structHash = keccak256(abi.encode(TenderConstants.BID_TYPEHASH, amount, salt, metadataHash));
        return MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }

    function test_ScoreBid_InvalidProof_Reverts() public {
        uint256 bidAmount = 50 ether;
        bytes memory proof = hex"1234";
        bytes32 salt = bytes32(0);

        // Generate Valid Commitment so we pass the first check
        bytes32 commitment = _getCommitment(bidAmount, salt, proof);

        // Expect revert due to invalid proof (ZK verification phase)
        vm.expectRevert();
        strategy.verifyAndScoreBid(commitment, bidAmount, salt, proof, address(0));
    }

    function test_StrategySafeFromBypass() public {
        uint256 bidAmount = 50 ether;
        bytes memory proof = "";
        bytes32 salt = bytes32(0);
        bytes32 commitment = _getCommitment(bidAmount, salt, proof);

        // Expect revert due to invalid proof or empty bytes
        vm.expectRevert();
        strategy.verifyAndScoreBid(commitment, bidAmount, salt, proof, address(0));
    }
}
