// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Tender} from "../contracts/Tender.sol";
import {TenderFactory} from "../contracts/TenderFactory.sol";
import {SignatureVerifier} from "../contracts/identity/SignatureVerifier.sol";
import {
    LowestPriceStrategy
} from "../contracts/strategies/LowestPriceStrategy.sol";
import {
    MessageHashUtils
} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TenderTest is Test {
    TenderFactory factory;
    Tender tender;
    SignatureVerifier signatureVerifier;
    LowestPriceStrategy priceStrategy;

    address authority = makeAddr("authority");
    address bidder1 = makeAddr("bidder1");
    address bidder2 = makeAddr("bidder2");
    address bidder3 = makeAddr("bidder3"); // Non-revealing bidder

    uint256 biddingTime = 1 days;
    uint256 revealTime = 1 days;
    uint256 bidBond = 1 ether;
    string configHash = "QmTestHash";

    bytes32 constant BID_TYPEHASH =
        keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)");

    function setUp() public {
        vm.startPrank(authority);
        TenderFactory impl = new TenderFactory();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(impl.initialize, ())
        );
        factory = TenderFactory(address(proxy));

        priceStrategy = new LowestPriceStrategy();

        uint256 challengePeriod = 1 days;
        address tenderAddr = factory.createTender(
            address(0),
            address(priceStrategy),
            configHash,
            biddingTime,
            revealTime,
            challengePeriod,
            bidBond
        );
        tender = Tender(tenderAddr);

        vm.stopPrank();
    }

    // Helper to generate EIP-712 Commitment
    function getCommitment(
        uint256 amount,
        bytes32 salt,
        bytes32 metadataHash
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(BID_TYPEHASH, amount, salt, metadataHash)
        );
        return
            MessageHashUtils.toTypedDataHash(
                tender.getDomainSeparator(),
                structHash
            );
    }

    function testInitialState() public view {
        assertEq(uint(tender.state()), uint(Tender.TenderState.CREATED));
    }

    function _getBidderId(address _user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ADDR_BIDDER", _user));
    }

    function testSubmitBid() public {
        vm.prank(authority);
        tender.openTendering();

        // Bidder 1: 100 ETH
        bytes32 salt = bytes32(uint256(1));
        bytes32 metadataHash = keccak256("metadata");
        uint256 amount = 100;

        bytes32 commitment = getCommitment(amount, salt, metadataHash);

        vm.deal(bidder1, 2 ether);
        bytes32[] memory emptySignals = new bytes32[](0);
        vm.prank(bidder1);
        tender.submitBid{value: bidBond}(commitment, "", emptySignals);

        bytes32 bidderId = _getBidderId(bidder1);
        (bytes32 savedCommitment, , , , bool revealed, ) = tender.bids(
            bidderId
        );
        assertEq(savedCommitment, commitment);
        assertFalse(revealed);
    }

    function testRevealBid() public {
        vm.prank(authority);
        tender.openTendering();

        bytes32 salt = bytes32(uint256(1));
        bytes32 metadataHash = keccak256("metadata");
        uint256 amount = 100;

        bytes32 commitment = getCommitment(amount, salt, metadataHash);

        vm.deal(bidder1, 2 ether);
        bytes32[] memory emptySignals = new bytes32[](0);
        vm.prank(bidder1);
        tender.submitBid{value: bidBond}(commitment, "", emptySignals);

        vm.warp(block.timestamp + biddingTime + 1);

        vm.prank(bidder1);
        tender.revealBid(amount, salt, bytes("metadata"));

        bytes32 bidderId = _getBidderId(bidder1);
        (, , , , bool revealed, ) = tender.bids(bidderId);
        assertTrue(revealed);
    }

    function testSlashingForNonReveal() public {
        vm.prank(authority);
        tender.openTendering();

        // Bidder 1 reveals (Good)
        bytes32 salt1 = bytes32(uint256(111));
        bytes32 meta1 = keccak256("meta1");
        uint256 amount1 = 1000;
        bytes32 commit1 = getCommitment(amount1, salt1, meta1);

        vm.deal(bidder1, 10 ether);
        vm.prank(bidder1);
        bytes32[] memory emptySignals = new bytes32[](0);
        tender.submitBid{value: bidBond}(commit1, "", emptySignals);

        // Bidder 3 does NEVER reveal (Loser/Malicious)
        bytes32 salt3 = bytes32(uint256(333));
        bytes32 meta3 = keccak256("meta3");
        uint256 amount3 = 5000;
        bytes32 commit3 = getCommitment(amount3, salt3, meta3);

        vm.deal(bidder3, 10 ether);
        vm.prank(bidder3);
        tender.submitBid{value: bidBond}(commit3, "", emptySignals);

        // 2. Reveal Phase
        vm.warp(block.timestamp + biddingTime + 1);
        vm.prank(bidder1);
        tender.revealBid(amount1, salt1, bytes("meta1"));

        // Bidder 3 misses reveal...

        // 3. Evaluation
        vm.warp(block.timestamp + revealTime + 1);

        vm.prank(authority);
        tender.evaluate();

        // Wait for challenge period to end to check forfeiture
        vm.warp(block.timestamp + 1 days + 1);

        // 4. Verify Slashing

        // Finalize first
        vm.prank(authority);
        tender.finalize();

        // Bidder 3 tries to withdraw
        vm.prank(bidder3);
        vm.expectRevert(Tender.BondForfeited.selector);
        tender.withdrawBond();

        // Authority claims slashed funds (Bidder 3's bond)
        uint256 authorityBalanceBefore = authority.balance;

        vm.prank(authority);
        tender.claimSlashedFunds();

        assertEq(authority.balance, authorityBalanceBefore + bidBond);
    }

    function testFullLifecycle() public {
        vm.prank(authority);
        tender.openTendering();

        // Bidder 1: 100 ETH
        vm.deal(bidder1, 10 ether);
        bytes32 salt1 = bytes32(uint256(111));
        bytes32 meta1 = keccak256("meta1");
        uint256 amount1 = 100;
        bytes32 commit1 = getCommitment(amount1, salt1, meta1);

        vm.prank(bidder1);
        bytes32[] memory emptySignals = new bytes32[](0);
        tender.submitBid{value: bidBond}(commit1, "", emptySignals);

        // Bidder 2: 90 ETH (Winner)
        vm.deal(bidder2, 10 ether);
        bytes32 salt2 = bytes32(uint256(222));
        bytes32 meta2 = keccak256("meta2");
        uint256 amount2 = 90;
        bytes32 commit2 = getCommitment(amount2, salt2, meta2);

        vm.prank(bidder2);
        tender.submitBid{value: bidBond}(commit2, "", emptySignals);

        vm.warp(block.timestamp + biddingTime + 1);

        vm.prank(bidder1);
        tender.revealBid(amount1, salt1, bytes("meta1"));

        vm.prank(bidder2);
        tender.revealBid(amount2, salt2, bytes("meta2"));

        vm.warp(block.timestamp + revealTime + 1);

        vm.prank(authority);
        tender.evaluate();

        assertEq(uint(tender.state()), uint(Tender.TenderState.AWARDED));
        bytes32 expectedWinnerId = _getBidderId(bidder2);
        assertEq(tender.winningBidderId(), expectedWinnerId);
    }
}
