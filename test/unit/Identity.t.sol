// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Tender } from "src/core/Tender.sol";
import { TenderFactory } from "src/core/TenderFactory.sol";
import { SignatureVerifier } from "src/identity/SignatureVerifier.sol";
import { LowestPriceStrategy } from "src/strategies/LowestPriceStrategy.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract IdentityTest is Test {
    using MessageHashUtils for bytes32;

    TenderFactory factory;
    Tender tender;
    SignatureVerifier signatureVerifier;

    address authority = makeAddr("authority");

    address issuer;
    uint256 issuerKey;

    address authorizedUser;
    uint256 authorizedUserKey; // Unused for verifying but good to have

    address maliciousUser = makeAddr("maliciousUser");

    uint256 biddingTime = 1 days;
    uint256 revealTime = 1 days;
    uint256 bidBond = 1 ether;
    string configHash = "QmTestHash";

    bytes32 constant BID_TYPEHASH = keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)");

    function setUp() public {
        // Setup Keys
        (issuer, issuerKey) = makeAddrAndKey("issuer");
        (authorizedUser, authorizedUserKey) = makeAddrAndKey("authorizedUser");

        // Deploy Factory and Verifier
        vm.startPrank(authority);
        TenderFactory impl = new TenderFactory();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeCall(impl.initialize, ()));
        factory = TenderFactory(address(proxy));
        vm.stopPrank();

        vm.prank(authority);
        signatureVerifier = new SignatureVerifier(issuer);

        // Strategies
        LowestPriceStrategy priceStrategy = new LowestPriceStrategy();

        // Deploy Tender with Verifier + Challenge Period
        vm.prank(authority);
        uint256 challengePeriod = 1 days;
        address tenderAddr = factory.createTender(
            address(signatureVerifier),
            address(priceStrategy),
            configHash,
            biddingTime,
            revealTime,
            challengePeriod,
            bidBond
        );
        tender = Tender(tenderAddr);
    }

    // --- Helpers ---
    function getCommitment(uint256 amount, bytes32 salt, bytes32 metadataHash) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(BID_TYPEHASH, amount, salt, metadataHash));
        return MessageHashUtils.toTypedDataHash(tender.getDomainSeparator(), structHash);
    }

    // --- Tests ---

    function _getBidderId(address _user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ADDR_BIDDER", _user));
    }

    function testAuthenticatedBid() public {
        vm.prank(authority);
        tender.openTendering();

        uint256 amount = 100;
        bytes32 salt = bytes32(uint256(1));
        bytes32 meta = keccak256("meta");
        bytes32 commit = getCommitment(amount, salt, meta);

        // Public Signals: [address(authorizedUser)]
        bytes32[] memory publicSignals = new bytes32[](1);
        publicSignals[0] = bytes32(uint256(uint160(authorizedUser)));

        // Generate Identity Proof (Signed by Issuer PRIVATE KEY)
        // Issuer signs the user's address (which is publicSignals[0])
        bytes32 messageHash = keccak256(abi.encodePacked(authorizedUser));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerKey, ethSignedMessageHash);
        bytes memory proof = abi.encodePacked(r, s, v);

        vm.deal(authorizedUser, 2 ether);
        vm.prank(authorizedUser);
        tender.submitBid{ value: bidBond }(commit, proof, publicSignals);

        // Verify storage (key is Hash(signal))
        // Note: Contract uses `_bidderIdFromSignal` which wraps the bytes32 signal.
        // Signal[0] is bytes32(address).
        bytes32 signalUser = bytes32(uint256(uint160(authorizedUser)));
        // Verify storage (key is Hash(signal))
        bytes32 expectedId = keccak256(abi.encodePacked("ADDR_BIDDER", signalUser));

        (bytes32 savedCommitment,,,,,) = tender.bids(expectedId);
        assertEq(savedCommitment, commit);
    }

    function testIdentityReplay() public {
        vm.prank(authority);
        tender.openTendering();

        uint256 amount = 100;
        bytes32 salt = bytes32(uint256(1));
        bytes32 meta = keccak256("meta");
        bytes32 commit = getCommitment(amount, salt, meta);

        // Public Signals: [address(authorizedUser)]
        bytes32[] memory publicSignals = new bytes32[](1);
        publicSignals[0] = bytes32(uint256(uint160(authorizedUser)));

        // Proof
        bytes32 messageHash = keccak256(abi.encodePacked(authorizedUser));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(issuerKey, ethSignedMessageHash);
        bytes memory proof = abi.encodePacked(r, s, v);

        // 1. Authorized user bids successfully
        vm.deal(authorizedUser, 2 ether);
        vm.prank(authorizedUser);
        tender.submitBid{ value: bidBond }(commit, proof, publicSignals);

        // 2. Malicious user tries to REPLAY the same valid proof + signal
        // Ideally this should fail because "One bid per bidderId"
        // And bidderId is derived from publicSignals[0].

        vm.deal(maliciousUser, 2 ether);
        vm.prank(maliciousUser);

        // This should Revert with BidAlreadyExists because bidderId collision
        vm.expectRevert(Tender.BidAlreadyExists.selector);
        tender.submitBid{ value: bidBond }(commit, proof, publicSignals);
    }

    function testUnauthenticatedBid_Revert() public {
        vm.prank(authority);
        tender.openTendering();

        uint256 amount = 100;
        bytes32 salt = bytes32(uint256(1));
        bytes32 meta = keccak256("meta");
        bytes32 commit = getCommitment(amount, salt, meta);

        bytes32[] memory publicSignals = new bytes32[](1);
        publicSignals[0] = bytes32(uint256(uint160(maliciousUser)));

        bytes memory fakeProof = "0x123";

        vm.deal(maliciousUser, 2 ether);
        vm.prank(maliciousUser);

        // Expect revert
        vm.expectRevert();
        tender.submitBid{ value: bidBond }(commit, fakeProof, publicSignals);
    }
}
