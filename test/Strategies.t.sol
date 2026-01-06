// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {
    LowestPriceStrategy
} from "../contracts/strategies/LowestPriceStrategy.sol";
import {
    WeightedScoreStrategy
} from "../contracts/strategies/WeightedScoreStrategy.sol";

contract StrategiesTest is Test {
    LowestPriceStrategy lowestPrice;
    WeightedScoreStrategy weighted;

    function setUp() public {
        lowestPrice = new LowestPriceStrategy();

        // PriceWeight = 1, DeliveryWeight = 2, ComplianceWeight = 5
        weighted = new WeightedScoreStrategy(1, 2, 5);
    }

    function testLowestPriceLogic() public view {
        assertTrue(lowestPrice.isLowerBetter());

        uint256 score1 = lowestPrice.scoreBid(100, "");
        assertEq(score1, 100);

        uint256 score2 = lowestPrice.scoreBid(500, "0x1234");
        assertEq(score2, 500);
    }

    function testWeightedLogic() public view {
        assertTrue(weighted.isLowerBetter());

        // Scenario 1:
        // Price: 100
        // Delivery: 10
        // Compliance: 90 (Max 100)
        // Score = (100 * 1) + (10 * 2) + (100 - 90) * 5
        //       = 100 + 20 + 50 = 170

        bytes memory metadata = abi.encode(uint256(10), uint256(90));
        uint256 score = weighted.scoreBid(100, metadata);
        assertEq(score, 170);

        // Scenario 2: Better compliance, slightly higher price
        // Price: 110 (Penalty +10)
        // Delivery: 10
        // Compliance: 100 (Max) -> Penalty 0
        // Score = (110 * 1) + (20) + 0 = 130
        // 130 < 170. Lower is better. So Scenario 2 wins.

        bytes memory meta2 = abi.encode(uint256(10), uint256(100));
        uint256 score2 = weighted.scoreBid(110, meta2);
        assertEq(score2, 130);

        assertTrue(score2 < score);
    }

    function testWeightedLogic_InvalidData() public view {
        // Empty bytes
        uint256 score = weighted.scoreBid(100, "");
        assertEq(score, type(uint256).max);
    }
}
