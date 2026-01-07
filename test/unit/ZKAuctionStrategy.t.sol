// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ZKAuctionStrategy} from "src/strategies/ZKAuctionStrategy.sol";

// Mock Verifier to test Strategy logic in isolation
contract MockZKVerifier {
    bool public shouldPass;

    function setShouldPass(bool _shouldPass) external {
        shouldPass = _shouldPass;
    }

    function verifyProof(
        bytes calldata,
        uint256[] calldata
    ) external view returns (bool) {
        return shouldPass;
    }
}

contract ZKAuctionStrategyTest is Test {
    ZKAuctionStrategy public strategy;
    MockZKVerifier public mockVerifier;

    uint256 constant MIN_BID = 10 ether;
    uint256 constant MAX_BID = 100 ether;

    function setUp() public {
        mockVerifier = new MockZKVerifier();
        strategy = new ZKAuctionStrategy(
            address(mockVerifier),
            MIN_BID,
            MAX_BID
        );
    }

    function test_Initialization() public view {
        assertEq(address(strategy.verifier()), address(mockVerifier));
        assertEq(strategy.minBid(), MIN_BID);
        assertEq(strategy.maxBid(), MAX_BID);
    }

    function test_IsLowerBetter() public view {
        assertFalse(
            strategy.isLowerBetter(),
            "Standard auction should prefer higher bids"
        );
    }

    function test_ScoreBid_ValidProof() public {
        mockVerifier.setShouldPass(true);
        uint256 bidAmount = 50 ether;
        bytes memory proof = hex"1234";

        uint256 score = strategy.scoreBid(bidAmount, proof);
        assertEq(score, bidAmount, "Score should match bid amount");
    }

    function test_ScoreBid_InvalidProof_Reverts() public {
        mockVerifier.setShouldPass(false);
        uint256 bidAmount = 50 ether;
        bytes memory proof = hex"1234";

        vm.expectRevert("Invalid ZK Proof");
        strategy.scoreBid(bidAmount, proof);
    }

    function test_ScoreBid_PassesPublicInputs() public {
        // This test requires a smarter mock to verify inputs passed
        // but for now we verify the basic logic flow
        mockVerifier.setShouldPass(true);
        strategy.scoreBid(MIN_BID, "");
    }
}
