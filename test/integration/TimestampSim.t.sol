// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Tender } from "src/core/Tender.sol";
import { TenderFactory } from "src/core/TenderFactory.sol";
import { LowestPriceStrategy } from "src/strategies/LowestPriceStrategy.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TimestampSim is Test {
    Tender public tender;
    TenderFactory public factory;
    LowestPriceStrategy public priceStrategy;

    address authority = makeAddr("authority");
    address bidder1 = makeAddr("bidder1");

    uint256 biddingTime = 1 days;

    function setUp() public {
        vm.startPrank(authority);
        TenderFactory impl = new TenderFactory();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeCall(impl.initialize, ()));
        factory = TenderFactory(address(proxy));

        priceStrategy = new LowestPriceStrategy();
        address tenderAddr = factory.createTender(
            Tender.IdentityMode.NONE,
            address(0),
            address(priceStrategy),
            "QmConfig",
            biddingTime,
            1 days,
            1 days,
            1 ether
        );
        tender = Tender(tenderAddr);
        tender.openTendering();
        vm.stopPrank();

        vm.deal(bidder1, 100 ether);
    }

    // Scenario: Miner/User submits bid exactly on the deadline edge.
    // If block.timestamp == biddingDeadline, it should FAIL (as per > logic? or >=?)
    // Tender.sol: if (block.timestamp >= biddingDeadline) revert InvalidTime
    function testExactDeadlineBoundary() public {
        uint256 deadline = tender.BIDDING_DEADLINE();

        vm.warp(deadline);

        // Preparation
        bytes32 salt = keccak256("salt");
        bytes32 meta = keccak256("meta");
        bytes32 bidTypehash = keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)");
        bytes32 structHash = keccak256(abi.encode(bidTypehash, 1 ether, salt, meta));
        bytes32 commitment = MessageHashUtils.toTypedDataHash(tender.getDomainSeparator(), structHash);

        vm.prank(bidder1);
        vm.expectRevert(); // Should revert InvalidTime
        tender.submitBid{ value: 1 ether }(commitment, "", new bytes32[](0));
    }

    function testJustBeforeDeadline() public {
        uint256 deadline = tender.BIDDING_DEADLINE();

        vm.warp(deadline - 1);

        // Preparation
        bytes32 salt = keccak256("salt");
        bytes32 meta = keccak256("meta");
        bytes32 bidTypehash = keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)");
        bytes32 structHash = keccak256(abi.encode(bidTypehash, 1 ether, salt, meta));
        bytes32 commitment = MessageHashUtils.toTypedDataHash(tender.getDomainSeparator(), structHash);

        vm.prank(bidder1);
        tender.submitBid{ value: 1 ether }(commitment, "", new bytes32[](0));
        // Should succeed
    }
}
