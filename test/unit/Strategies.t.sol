// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { LowestPriceStrategy } from "src/strategies/LowestPriceStrategy.sol";
import { WeightedScoreStrategy } from "src/strategies/WeightedScoreStrategy.sol";
import { TenderConstants } from "src/libraries/TenderConstants.sol";

contract StrategiesTest is Test {
    LowestPriceStrategy lowestPrice;
    WeightedScoreStrategy weighted;

    function setUp() public {
        lowestPrice = new LowestPriceStrategy();

        // PriceWeight = 1, DeliveryWeight = 2, ComplianceWeight = 5
        weighted = new WeightedScoreStrategy(1, 2, 5);
    }

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

    function testLowestPriceLogic() public view {
        assertTrue(lowestPrice.isLowerBetter());

        bytes32 salt = bytes32(0);
        bytes memory metadata = "";
        uint256 amount = 100;
        bytes32 commitment = _getCommitment(amount, salt, metadata);

        uint256 score1 = lowestPrice.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        assertEq(score1, 100);

        amount = 500;
        metadata = "0x1234";
        commitment = _getCommitment(amount, salt, metadata);
        uint256 score2 = lowestPrice.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        assertEq(score2, 500);
    }

    function testWeightedLogic() public view {
        assertTrue(weighted.isLowerBetter());
        bytes32 salt = bytes32(0);

        // Scenario 1:
        bytes memory metadata = abi.encode(uint256(10), uint256(90));
        uint256 amount = 100;
        bytes32 commitment = _getCommitment(amount, salt, metadata);
        uint256 score = weighted.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        assertEq(score, 170);
        // So 170 is wrong if unit is ether.
        // Ah, original comment said "Price=100 ETH". If code passes 100 ether, score is huge.
        // Wait, line 40 was `scoreBid(100, metadata)`.
        // So price is 100 wei.
        // Test says `// Bidder submits: Price=100 ETH` in comment, but code used `100` (wei)?
        // No, line 40 in Snippet (Step 346) says `weighted.scoreBid(100, metadata)`.
        // Example in comment (Line 36) says `100 ether`.
        // Line 40 code says `100`.
        // Let's stick to `100`.

        // Recalculating expected:
        // Price 100. W=1. -> 100.
        // Delivery 10. W=2. -> 20.
        // Compliance 90. Max 100. Diff 10. W=5. -> 50.
        // Total = 100 + 20 + 50 = 170.
        // So `100` (wei) is correct.
    }

    function testWeightedLogic_Complex() public view {
        // Redoing the Scenario 1 & 2 logic correctly with verifyAndScoreBid
        bytes32 salt = bytes32(0);

        // Scenario 1
        uint256 amount1 = 100;
        bytes memory meta1 = abi.encode(uint256(10), uint256(90));
        bytes32 comm1 = _getCommitment(amount1, salt, meta1);
        uint256 score1 = weighted.verifyAndScoreBid(comm1, amount1, salt, meta1, address(0));
        assertEq(score1, 170);

        // Scenario 2
        uint256 amount2 = 110;
        bytes memory meta2 = abi.encode(uint256(10), uint256(100));
        bytes32 comm2 = _getCommitment(amount2, salt, meta2);
        uint256 score2 = weighted.verifyAndScoreBid(comm2, amount2, salt, meta2, address(0));
        assertEq(score2, 130);

        assertTrue(score2 < score1);
    }

    function testWeightedLogic_InvalidData() public view {
        // Empty bytes
        uint256 amount = 100;
        bytes32 salt = bytes32(0);
        bytes memory metadata = "";
        bytes32 commitment = _getCommitment(amount, salt, metadata);

        uint256 score = weighted.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        assertEq(score, type(uint256).max);
    }

    // ============ Additional WeightedScoreStrategy Tests ============

    function testWeighted_ZeroCompliance() public view {
        uint256 amount = 100;
        bytes32 salt = bytes32(0);
        bytes memory metadata = abi.encode(uint256(10), uint256(0));
        bytes32 commitment = _getCommitment(amount, salt, metadata);

        uint256 score = weighted.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        // Score = 100*1 + 10*2 + 100*5 = 100 + 20 + 500 = 620
        assertEq(score, 620);
    }

    function testWeighted_MaxCompliance() public view {
        uint256 amount = 100;
        bytes32 salt = bytes32(0);
        bytes memory metadata = abi.encode(uint256(10), uint256(100));
        bytes32 commitment = _getCommitment(amount, salt, metadata);
        uint256 score = weighted.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        // Score = 100*1 + 10*2 + 0*5 = 100 + 20 + 0 = 120
        assertEq(score, 120);
    }

    function testWeighted_ComplianceOverMax() public view {
        uint256 amount = 100;
        bytes32 salt = bytes32(0);
        bytes memory metadata = abi.encode(uint256(10), uint256(150));
        bytes32 commitment = _getCommitment(amount, salt, metadata);
        uint256 score = weighted.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        // Score = 100*1 + 10*2 + 0*5 = 120
        assertEq(score, 120);
    }

    function testWeighted_ZeroDelivery() public view {
        uint256 amount = 100;
        bytes32 salt = bytes32(0);
        bytes memory metadata = abi.encode(uint256(0), uint256(50));
        bytes32 commitment = _getCommitment(amount, salt, metadata);
        uint256 score = weighted.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        // Score = 100*1 + 0*2 + 50*5 = 100 + 0 + 250 = 350
        assertEq(score, 350);
    }

    function testWeighted_ZeroPrice() public view {
        uint256 amount = 0;
        bytes32 salt = bytes32(0);
        bytes memory metadata = abi.encode(uint256(10), uint256(50));
        bytes32 commitment = _getCommitment(amount, salt, metadata);
        uint256 score = weighted.verifyAndScoreBid(commitment, amount, salt, metadata, address(0));
        // Score = 0*1 + 10*2 + 50*5 = 0 + 20 + 250 = 270
        assertEq(score, 270);
    }

    function testWeighted_HighWeightsPreference() public view {
        bytes32 salt = bytes32(0);

        // Bid A: Price 200, Delivery 5, Compliance 90
        uint256 priceA = 200;
        bytes memory metaA = abi.encode(uint256(5), uint256(90));
        bytes32 commA = _getCommitment(priceA, salt, metaA);
        uint256 scoreA = weighted.verifyAndScoreBid(commA, priceA, salt, metaA, address(0));
        // = 200 + 10 + 50 = 260

        // Bid B: Price 100, Delivery 5, Compliance 70
        uint256 priceB = 100;
        bytes memory metaB = abi.encode(uint256(5), uint256(70));
        bytes32 commB = _getCommitment(priceB, salt, metaB);
        uint256 scoreB = weighted.verifyAndScoreBid(commB, priceB, salt, metaB, address(0));
        // = 100 + 10 + 150 = 260

        assertEq(scoreA, scoreB);
    }

    function testFuzz_WeightedScoring(uint256 price, uint256 delivery, uint256 compliance) public view {
        // Bound inputs to reasonable ranges
        price = bound(price, 0, 1e18);
        delivery = bound(delivery, 0, 365 days);
        compliance = bound(compliance, 0, 100);
        bytes32 salt = bytes32(0);

        bytes memory metadata = abi.encode(delivery, compliance);
        bytes32 commitment = _getCommitment(price, salt, metadata);
        uint256 score = weighted.verifyAndScoreBid(commitment, price, salt, metadata, address(0));

        // Score should be deterministic
        uint256 expected = (price * 1) + (delivery * 2) + ((100 - compliance) * 5);
        assertEq(score, expected);
    }
}
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
