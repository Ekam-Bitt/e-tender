// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Tender.sol";
import "../src/TenderFactory.sol";

contract TenderTest is Test {
    TenderFactory factory;
    Tender tender;
    
    address authority = address(1);
    address bidder1 = address(2);
    address bidder2 = address(3);
    address bidder3 = address(4); // Malicious or late

    uint256 biddingTime = 1 days;
    uint256 revealTime = 1 days;
    uint256 bidBond = 1 ether;
    string configHash = "QmTestHash";

    function setUp() public {
        vm.prank(authority);
        factory = new TenderFactory();
        
        vm.prank(authority);
        address tenderAddr = factory.createTender(configHash, biddingTime, revealTime, bidBond);
        tender = Tender(tenderAddr);
    }

    function testInitialState() public view {
        assertEq(uint(tender.state()), uint(Tender.TenderState.CREATED));
        assertEq(tender.authority(), authority);
        assertEq(tender.bidBondAmount(), bidBond);
    }

    function testOpenTendering() public {
        vm.prank(authority);
        tender.openTendering();
        assertEq(uint(tender.state()), uint(Tender.TenderState.OPEN));
    }

    function testSubmitBidBeforeOpen_Revert() public {
        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        vm.expectRevert(abi.encodeWithSelector(Tender.InvalidState.selector, Tender.TenderState.CREATED, Tender.TenderState.OPEN));
        tender.submitBid{value: bidBond}(bytes32(0));
    }

    function testSubmitBid() public {
        vm.prank(authority);
        tender.openTendering();

        bytes32 salt = bytes32(uint256(123));
        uint256 amount = 100;
        bytes32 commitment = keccak256(abi.encodePacked(amount, salt));

        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        tender.submitBid{value: bidBond}(commitment);

        (bytes32 savedCommitment,,,,bool revealed) = tender.bids(bidder1);
        assertEq(savedCommitment, commitment);
        assertFalse(revealed);
    }

    function testRevealBid() public {
        // 1. Setup & Bid
        vm.prank(authority);
        tender.openTendering();

        bytes32 salt = bytes32(uint256(123));
        uint256 amount = 100;
        bytes32 commitment = keccak256(abi.encodePacked(amount, salt));

        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        tender.submitBid{value: bidBond}(commitment);

        // 2. Warping time to Reveal Phase
        vm.warp(block.timestamp + biddingTime + 1);
        
        // 3. Reveal
        vm.prank(bidder1);
        tender.revealBid(amount, salt);

        (,,,,bool revealed) = tender.bids(bidder1);
        assertTrue(revealed);
    }

    function testFullLifecycle() public {
        // --- OPEN ---
        vm.prank(authority);
        tender.openTendering();

        // Bidder 1: 100 ETH
        vm.deal(bidder1, 10 ether);
        bytes32 salt1 = bytes32(uint256(111));
        uint256 amount1 = 100;
        vm.prank(bidder1);
        tender.submitBid{value: bidBond}(keccak256(abi.encodePacked(amount1, salt1)));

        // Bidder 2: 90 ETH (Winner)
        vm.deal(bidder2, 10 ether);
        bytes32 salt2 = bytes32(uint256(222));
        uint256 amount2 = 90;
        vm.prank(bidder2);
        tender.submitBid{value: bidBond}(keccak256(abi.encodePacked(amount2, salt2)));

        // --- REVEAL ---
        vm.warp(block.timestamp + biddingTime + 1);

        vm.prank(bidder1);
        tender.revealBid(amount1, salt1);

        vm.prank(bidder2);
        tender.revealBid(amount2, salt2);

        // --- EVALUATE ---
        vm.warp(block.timestamp + revealTime + 1);
        
        vm.prank(authority);
        tender.evaluate();

        assertEq(uint(tender.state()), uint(Tender.TenderState.AWARDED));
        assertEq(tender.winner(), bidder2);
        assertEq(tender.winningAmount(), 90);
    }
}
