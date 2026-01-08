// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Tender} from "src/core/Tender.sol";
import {TenderFactory} from "src/core/TenderFactory.sol";
import {LowestPriceStrategy} from "src/strategies/LowestPriceStrategy.sol";
import {
    MessageHashUtils
} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TenderHandler is Test {
    Tender public tender;
    TenderFactory public factory;
    LowestPriceStrategy public priceStrategy;

    address public authority;
    address[] public bidders;

    // Ghost variables to track expected state
    uint256 public sumDeposits;

    uint256 public constant BID_BOND = 1 ether;

    constructor(Tender _tender, TenderFactory _factory, address _authority) {
        tender = _tender;
        factory = _factory;
        authority = _authority;
        priceStrategy = new LowestPriceStrategy();
    }

    function createBidders(uint256 count) public {
        for (uint256 i = 0; i < count; i++) {
            bidders.push(makeAddr(string(abi.encodePacked("bidder", i))));
            vm.deal(bidders[i], 100 ether);
        }
    }

    // ACTION: Open Tendering
    function openTendering() public {
        if (tender.state() == Tender.TenderState.CREATED) {
            vm.prank(authority);
            tender.openTendering();
        }
    }

    // ACTION: Submit Bid
    function submitBid(uint256 bidderIdx, uint256 amount, bytes32 salt) public {
        if (tender.state() != Tender.TenderState.OPEN) return;
        if (bidders.length == 0) return;

        // Bound inputs
        bidderIdx = bound(bidderIdx, 0, bidders.length - 1);
        amount = bound(amount, 10 ether, 1000 ether); // Realistic range

        address bidder = bidders[bidderIdx];

        // Generate Commitment
        bytes32 metadataHash = keccak256("meta");
        bytes32 bidTypehash = keccak256(
            "Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)"
        );
        bytes32 structHash = keccak256(
            abi.encode(bidTypehash, amount, salt, metadataHash)
        );
        bytes32 commitment = MessageHashUtils.toTypedDataHash(
            tender.getDomainSeparator(),
            structHash
        );

        vm.prank(bidder);
        vm.prank(bidder);
        // NOTE: In invariant tests, we are focusing on protocol flow, not ZK verification.
        // We use empty proof. The Strategy deployed in Invariants setup MUST be a mock or permissive one.
        // However, Invariants file deploys LowestPriceStrategy which doesn't check proofs!
        // So just passing empty bytes is fine.
        try
            tender.submitBid{value: BID_BOND}(commitment, "", new bytes32[](0))
        {
            sumDeposits += BID_BOND;
        } catch {}
    }

    // ACTION: Reveal Bid
    // We need to track who submitted what to reveal successfully?
    // For fuzzing, we can store valid params in a ghost mapping or just try random.
    // To find bugs, random is good, but to reach deep state, we need valid reveals.
    // Let's rely on InvariantTest calling `submitBid` properly.

    // Warping helper
    function warpToReveal() public {
        if (tender.state() == Tender.TenderState.OPEN) {
            vm.warp(tender.BIDDING_DEADLINE() + 1);
        }
    }

    function warpToEval() public {
        if (tender.state() == Tender.TenderState.REVEAL_PERIOD) {
            vm.warp(tender.REVEAL_DEADLINE() + 1);
        }
    }
}
