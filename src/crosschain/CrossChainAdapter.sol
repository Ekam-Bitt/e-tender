// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICrossChainAdapter } from "../interfaces/ICrossChainAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// ============ CCIP Types (matching Chainlink naming) ============

/// @notice CCIP EVM2Any message structure
struct Evm2AnyMessage {
    bytes receiver;
    bytes data;
    EvmTokenAmount[] tokenAmounts;
    address feeToken;
    bytes extraArgs;
}

/// @notice Token amount for CCIP
struct EvmTokenAmount {
    address token;
    uint256 amount;
}

/// @notice CCIP Any2EVM message structure (received)
struct Any2EvmMessage {
    bytes32 messageId;
    uint64 sourceChainSelector;
    bytes sender;
    bytes data;
    EvmTokenAmount[] destTokenAmounts;
}

/// @notice Minimal CCIP Router interface
interface IRouterClient {
    function ccipSend(uint64 destinationChainSelector, Evm2AnyMessage memory message) external payable returns (bytes32);

    function getFee(uint64 destinationChainSelector, Evm2AnyMessage memory message) external view returns (uint256);
}

/// @notice Interface for Tender cross-chain bid submission
interface ITender {
    function submitCrossChainBid(bytes32 commitment, bytes32 bidderId, uint64 sourceChain) external payable;
}

/**
 * @title CCIPBidReceiver
 * @notice Receives cross-chain bids via Chainlink CCIP and forwards to Tender
 * @dev Deployed on the destination chain alongside Tender contracts
 *
 * Architecture:
 *   [Source Chain]                    [Destination Chain]
 *   CCIPBidSender  ---> CCIP ---> CCIPBidReceiver ---> Tender.submitCrossChainBid()
 */
contract CCIPBidReceiver is ICrossChainAdapter, Ownable {
    // ============ State ============

    /// @notice CCIP Router address
    IRouterClient public immutable ROUTER;

    /// @notice Tender contract that receives bids
    address public tender;

    /// @notice Bond amount to forward with cross-chain bids
    uint256 public bidBondAmount;

    /// @notice Allowed source chains (chainSelector => allowed)
    mapping(uint64 => bool) public allowedSourceChains;

    /// @notice Allowed source senders per chain (chainSelector => sender => allowed)
    mapping(uint64 => mapping(address => bool)) public allowedSenders;

    /// @notice Processed message IDs (for replay protection)
    mapping(bytes32 => bool) public processedMessages;

    // ============ Events ============

    event TenderSet(address indexed tender);
    event BondAmountSet(uint256 amount);
    event SourceChainAllowed(uint64 indexed chainSelector, bool allowed);
    event SenderAllowed(uint64 indexed chainSelector, address indexed sender, bool allowed);

    // ============ Errors ============

    error TenderNotSet();
    error MessageAlreadyProcessed(bytes32 messageId);
    error OnlyRouter();
    error InsufficientBondBalance();

    // ============ Constructor ============

    constructor(address _router) Ownable(msg.sender) {
        ROUTER = IRouterClient(_router);
    }

    // ============ Admin Functions ============

    function setTender(address _tender) external onlyOwner {
        tender = _tender;
        emit TenderSet(_tender);
    }

    function setBidBondAmount(uint256 _amount) external onlyOwner {
        bidBondAmount = _amount;
        emit BondAmountSet(_amount);
    }

    function allowSourceChain(uint64 chainSelector, bool allowed) external onlyOwner {
        allowedSourceChains[chainSelector] = allowed;
        emit SourceChainAllowed(chainSelector, allowed);
    }

    function allowSender(uint64 chainSelector, address sender, bool allowed) external onlyOwner {
        allowedSenders[chainSelector][sender] = allowed;
        emit SenderAllowed(chainSelector, sender, allowed);
    }

    // ============ ICrossChainAdapter Implementation ============

    /// @inheritdoc ICrossChainAdapter
    function estimateFee(uint64 destChainSelector, address destTender, bytes32 commitment)
        external
        view
        override
        returns (uint256)
    {
        bytes memory payload = abi.encode(commitment, msg.sender);

        Evm2AnyMessage memory message = Evm2AnyMessage({
            receiver: abi.encode(destTender),
            data: payload,
            tokenAmounts: new EvmTokenAmount[](0),
            feeToken: address(0), // Pay in native
            extraArgs: ""
        });

        return ROUTER.getFee(destChainSelector, message);
    }

    /// @inheritdoc ICrossChainAdapter
    function sendBid(uint64 destChainSelector, address destTender, bytes32 commitment)
        external
        payable
        override
        returns (bytes32 messageId)
    {
        bytes memory payload = abi.encode(commitment, msg.sender);

        Evm2AnyMessage memory message = Evm2AnyMessage({
            receiver: abi.encode(destTender),
            data: payload,
            tokenAmounts: new EvmTokenAmount[](0),
            feeToken: address(0),
            extraArgs: ""
        });

        uint256 fee = ROUTER.getFee(destChainSelector, message);
        if (msg.value < fee) {
            revert InsufficientFee(fee, msg.value);
        }

        messageId = ROUTER.ccipSend{ value: fee }(destChainSelector, message);

        emit CrossChainBidSent(destChainSelector, destTender, commitment, messageId);

        // Refund excess
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }

    /// @inheritdoc ICrossChainAdapter
    function receiveMessage(uint64 sourceChainSelector, address sourceSender, bytes calldata payload)
        external
        override
    {
        if (!allowedSourceChains[sourceChainSelector]) {
            revert InvalidSourceChain(sourceChainSelector);
        }

        if (!allowedSenders[sourceChainSelector][sourceSender]) {
            revert InvalidSourceSender(sourceSender);
        }

        _processPayload(sourceChainSelector, sourceSender, payload);
    }

    /**
     * @notice CCIP callback for receiving messages
     * @dev This follows the CCIPReceiver pattern
     */
    function ccipReceive(Any2EvmMessage calldata message) external {
        if (msg.sender != address(ROUTER)) revert OnlyRouter();

        bytes32 messageId = message.messageId;
        if (processedMessages[messageId]) {
            revert MessageAlreadyProcessed(messageId);
        }
        processedMessages[messageId] = true;

        uint64 sourceChainSelector = message.sourceChainSelector;
        address sourceSender = abi.decode(message.sender, (address));

        if (!allowedSourceChains[sourceChainSelector]) {
            revert InvalidSourceChain(sourceChainSelector);
        }

        if (!allowedSenders[sourceChainSelector][sourceSender]) {
            revert InvalidSourceSender(sourceSender);
        }

        _processPayload(sourceChainSelector, sourceSender, message.data);
    }

    // ============ Internal Functions ============

    function _processPayload(uint64 sourceChainSelector, address, bytes calldata payload) internal {
        if (tender == address(0)) revert TenderNotSet();

        // Decode payload: (commitment, originalSender)
        (bytes32 commitment, address originalSender) = abi.decode(payload, (bytes32, address));

        // Compute bidderId from source chain info
        bytes32 bidderId = keccak256(abi.encodePacked("CROSSCHAIN_BIDDER", sourceChainSelector, originalSender));

        emit CrossChainBidReceived(sourceChainSelector, originalSender, commitment, bidderId);

        // Forward to Tender with bond
        if (address(this).balance < bidBondAmount) {
            revert InsufficientBondBalance();
        }
        ITender(tender).submitCrossChainBid{ value: bidBondAmount }(commitment, bidderId, sourceChainSelector);
    }

    // ============ Receive ============

    receive() external payable { }
}
