// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import {
    CCIPBidReceiver,
    IRouterClient,
    Evm2AnyMessage,
    EvmTokenAmount,
    Any2EvmMessage
} from "src/crosschain/CrossChainAdapter.sol";

/// @notice Mock CCIP Router for testing
contract MockCCIPRouter is IRouterClient {
    uint256 public constant MOCK_FEE = 0.01 ether;
    bytes32 public lastMessageId;
    uint256 public messageCount;

    function ccipSend(uint64, Evm2AnyMessage memory) external payable override returns (bytes32) {
        messageCount++;
        lastMessageId = keccak256(abi.encodePacked(block.timestamp, messageCount));
        return lastMessageId;
    }

    function getFee(uint64, Evm2AnyMessage memory) external pure override returns (uint256) {
        return MOCK_FEE;
    }
}

/// @notice Mock Tender for testing cross-chain bid reception
contract MockTender {
    bytes32 public lastCommitment;
    bytes32 public lastBidderId;
    uint64 public lastSourceChain;
    uint256 public bidCount;

    function submitCrossChainBid(bytes32 commitment, bytes32 bidderId, uint64 sourceChain) external payable {
        lastCommitment = commitment;
        lastBidderId = bidderId;
        lastSourceChain = sourceChain;
        bidCount++;
    }
}

contract CrossChainAdapterTest is Test {
    CCIPBidReceiver public receiver;
    MockCCIPRouter public mockRouter;
    MockTender public mockTender;

    address owner = makeAddr("owner");
    address remoteSender = makeAddr("remoteSender");
    uint64 constant SEPOLIA_SELECTOR = 16015286601757825753;
    uint64 constant FUJI_SELECTOR = 14767482510784806043;

    function setUp() public {
        vm.startPrank(owner);
        mockRouter = new MockCCIPRouter();
        mockTender = new MockTender();
        receiver = new CCIPBidReceiver(address(mockRouter));
        receiver.setTender(address(mockTender));
        receiver.setBidBondAmount(0.01 ether);
        receiver.allowSourceChain(FUJI_SELECTOR, true);
        receiver.allowSender(FUJI_SELECTOR, remoteSender, true);
        vm.stopPrank();

        // Fund receiver for bid bonds
        vm.deal(address(receiver), 10 ether);
    }

    function test_Initialization() public view {
        assertEq(address(receiver.ROUTER()), address(mockRouter));
        assertEq(receiver.tender(), address(mockTender));
        assertEq(receiver.owner(), owner);
    }

    function test_AllowSourceChain() public {
        vm.prank(owner);
        receiver.allowSourceChain(SEPOLIA_SELECTOR, true);
        assertTrue(receiver.allowedSourceChains(SEPOLIA_SELECTOR));
    }

    function test_AllowSender() public {
        address newSender = makeAddr("newSender");
        vm.prank(owner);
        receiver.allowSender(FUJI_SELECTOR, newSender, true);
        assertTrue(receiver.allowedSenders(FUJI_SELECTOR, newSender));
    }

    function test_EstimateFee() public view {
        bytes32 commitment = keccak256("test commitment");
        uint256 fee = receiver.estimateFee(FUJI_SELECTOR, address(mockTender), commitment);
        assertEq(fee, mockRouter.MOCK_FEE());
    }

    function test_SendBid() public {
        bytes32 commitment = keccak256("test commitment");
        address bidder = makeAddr("bidder");
        vm.deal(bidder, 1 ether);

        vm.prank(bidder);
        bytes32 messageId = receiver.sendBid{ value: 0.1 ether }(FUJI_SELECTOR, address(mockTender), commitment);

        assertEq(messageId, mockRouter.lastMessageId());
        assertEq(mockRouter.messageCount(), 1);
    }

    function test_SendBid_RefundsExcess() public {
        bytes32 commitment = keccak256("test");
        address bidder = makeAddr("bidder");
        vm.deal(bidder, 1 ether);

        uint256 balanceBefore = bidder.balance;

        vm.prank(bidder);
        receiver.sendBid{ value: 0.5 ether }(FUJI_SELECTOR, address(mockTender), commitment);

        assertEq(bidder.balance, balanceBefore - mockRouter.MOCK_FEE());
    }

    function test_SendBid_RevertInsufficientFee() public {
        bytes32 commitment = keccak256("test");
        address bidder = makeAddr("bidder");
        vm.deal(bidder, 0.001 ether);

        vm.prank(bidder);
        vm.expectRevert();
        receiver.sendBid{ value: 0.001 ether }(FUJI_SELECTOR, address(mockTender), commitment);
    }

    function test_ReceiveMessage_Success() public {
        bytes32 commitment = keccak256("cross-chain bid");
        address originalSender = makeAddr("originalSender");
        bytes memory payload = abi.encode(commitment, originalSender);

        vm.prank(address(mockRouter));
        receiver.receiveMessage(FUJI_SELECTOR, remoteSender, payload);

        // Verify tender received the bid
        assertEq(mockTender.lastCommitment(), commitment);
        assertEq(mockTender.bidCount(), 1);
    }

    function test_ReceiveMessage_RevertInvalidChain() public {
        bytes memory payload = abi.encode(bytes32(0), address(0));

        vm.prank(address(mockRouter));
        vm.expectRevert();
        receiver.receiveMessage(SEPOLIA_SELECTOR, remoteSender, payload);
    }

    function test_ReceiveMessage_RevertInvalidSender() public {
        address badSender = makeAddr("badSender");
        bytes memory payload = abi.encode(bytes32(0), address(0));

        vm.prank(address(mockRouter));
        vm.expectRevert();
        receiver.receiveMessage(FUJI_SELECTOR, badSender, payload);
    }

    function test_CcipReceive_ReplayProtection() public {
        bytes32 commitment = keccak256("bid");
        bytes memory payload = abi.encode(commitment, remoteSender);

        Any2EvmMessage memory message = Any2EvmMessage({
            messageId: keccak256("msg1"),
            sourceChainSelector: FUJI_SELECTOR,
            sender: abi.encode(remoteSender),
            data: payload,
            destTokenAmounts: new EvmTokenAmount[](0)
        });

        vm.prank(address(mockRouter));
        receiver.ccipReceive(message);

        // Same message again should fail
        vm.prank(address(mockRouter));
        vm.expectRevert();
        receiver.ccipReceive(message);
    }

    function test_OnlyOwnerCanConfigure() public {
        address notOwner = makeAddr("notOwner");

        vm.prank(notOwner);
        vm.expectRevert();
        receiver.setTender(address(1));

        vm.prank(notOwner);
        vm.expectRevert();
        receiver.allowSourceChain(1, true);
    }

    function test_CrossChainBidIntegration() public {
        bytes32 commitment = keccak256("full integration test");
        address originalBidder = makeAddr("originalBidder");
        bytes memory payload = abi.encode(commitment, originalBidder);

        // Simulate CCIP receiving message
        vm.prank(address(mockRouter));
        receiver.receiveMessage(FUJI_SELECTOR, remoteSender, payload);

        // Verify full flow
        assertEq(mockTender.lastCommitment(), commitment);
        assertEq(mockTender.lastSourceChain(), FUJI_SELECTOR);

        // Verify bidderId computation
        bytes32 expectedBidderId = keccak256(abi.encodePacked("CROSSCHAIN_BIDDER", FUJI_SELECTOR, originalBidder));
        assertEq(mockTender.lastBidderId(), expectedBidderId);
    }
}
