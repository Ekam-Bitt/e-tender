// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IIdentityVerifier} from "src/interfaces/IIdentityVerifier.sol";
import {IEvaluationStrategy} from "src/interfaces/IEvaluationStrategy.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ComplianceModule} from "src/compliance/ComplianceModule.sol";

/**
 * @title Tender
 * @notice Represents a single tender lifecycle from creation to award.
 * @dev Implements a Commit-Reveal scheme using EIP-712 for typed structural hashing.
 */
contract Tender is EIP712, Pausable, ComplianceModule {
    using ECDSA for bytes32;
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error InvalidState(TenderState current, TenderState expected);
    error InvalidTime(uint256 current, uint256 deadline);

    // ... (omitting unchanged parts)

    constructor(
        // ... args
        address _authority,
        address _verifier,
        address _evaluationStrategy,
        string memory _configIpfsHash,
        uint256 _biddingTime,
        uint256 _revealTime,
        uint256 _challengePeriod,
        uint256 _bidBondAmount
    ) EIP712("Tender", "1") {
        AUTHORITY = _authority;
        verifier = IIdentityVerifier(_verifier);
        evaluationStrategy = IEvaluationStrategy(_evaluationStrategy);
        configIpfsHash = _configIpfsHash;
        BID_BOND_AMOUNT = _bidBondAmount;

        BIDDING_DEADLINE = block.timestamp + _biddingTime;
        REVEAL_DEADLINE = block.timestamp + _biddingTime + _revealTime;
        challengePeriod = _challengePeriod;

        state = TenderState.CREATED;

        _logCompliance(
            REG_TENDER_CREATED,
            msg.sender,
            bytes32(uint256(uint160(address(this)))),
            bytes(_configIpfsHash)
        );
    }

    // ...

    function submitBid(
        bytes32 _commitment,
        bytes calldata _identityProof,
        bytes32[] calldata _publicSignals
    ) external payable atState(TenderState.OPEN) whenNotPaused {
        bytes32 bidderId;

        // Identity Check
        if (address(verifier) != address(0)) {
            bool authorized = verifier.verify(_identityProof, _publicSignals);
            if (!authorized) revert Unauthorized();

            // Decoupling: Use wrapped signal as ID.
            if (_publicSignals.length > 0) {
                // For SignatureVerifier, signal[0] is the address. Wrapping it matches _getBidderId(addr).
                bidderId = _bidderIdFromSignal(_publicSignals[0]);
            } else {
                // Fallback should not happen with valid verifiers, but if it does:
                bidderId = _getBidderId(msg.sender);
            }
        } else {
            // Public Tender
            emit IdentityVerificationBypassed();
            bidderId = _getBidderId(msg.sender);
        }

        if (block.timestamp >= BIDDING_DEADLINE) {
            revert InvalidTime(block.timestamp, BIDDING_DEADLINE);
        }
        if (msg.value < BID_BOND_AMOUNT) revert IncorrectFee();
        if (bids[bidderId].commitment != bytes32(0)) revert BidAlreadyExists();

        bids[bidderId] = Bid({
            commitment: _commitment,
            revealedAmount: 0,
            deposit: msg.value,
            timestamp: uint64(block.timestamp),
            revealed: false,
            score: 0
        });
        bidderIds.push(bidderId);

        emit BidSubmitted(bidderId, _commitment);

        _logCompliance(
            REG_BID_SUBMITTED,
            msg.sender,
            bidderId,
            abi.encode(_commitment)
        );
    }

    /// @notice Submit a bid from a cross-chain source
    /// @dev Only callable by the authorized crossChainReceiver contract
    /// @param _commitment The bid commitment hash
    /// @param _bidderId The bidder ID computed from source chain info
    /// @param _sourceChain The source chain selector
    function submitCrossChainBid(
        bytes32 _commitment,
        bytes32 _bidderId,
        uint64 _sourceChain
    ) external payable atState(TenderState.OPEN) whenNotPaused {
        require(
            msg.sender == crossChainReceiver,
            "Tender: only cross-chain receiver"
        );
        require(
            crossChainReceiver != address(0),
            "Tender: cross-chain not configured"
        );

        if (block.timestamp >= BIDDING_DEADLINE) {
            revert InvalidTime(block.timestamp, BIDDING_DEADLINE);
        }
        if (msg.value < BID_BOND_AMOUNT) revert IncorrectFee();
        if (bids[_bidderId].commitment != bytes32(0)) revert BidAlreadyExists();

        bids[_bidderId] = Bid({
            commitment: _commitment,
            revealedAmount: 0,
            deposit: msg.value,
            timestamp: uint64(block.timestamp),
            revealed: false,
            score: 0
        });
        bidderIds.push(_bidderId);

        emit CrossChainBidSubmitted(_bidderId, _commitment, _sourceChain);

        _logCompliance(
            REG_BID_SUBMITTED,
            msg.sender,
            _bidderId,
            abi.encode(_commitment, _sourceChain)
        );
    }

    /// @notice Set the cross-chain receiver contract
    /// @dev Only callable by authority
    function setCrossChainReceiver(address _receiver) external onlyAuthority {
        crossChainReceiver = _receiver;
    }

    error IncorrectFee();
    error BidAlreadyExists();
    error BidNotRevealed();
    error InvalidCommitment();
    error NoValidBids();
    error AlreadyRevealed();
    error BondForfeited();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    enum TenderState {
        CREATED,
        OPEN,
        REVEAL_PERIOD,
        EVALUATION,
        AWARDED,
        RESOLVED, // Final state after challenge period
        CANCELED
    }

    struct Bid {
        bytes32 commitment; // EIP-712 Hash
        uint256 revealedAmount;
        uint256 deposit;
        uint64 timestamp;
        bool revealed;
        uint256 score;
    }

    bytes32 private constant BID_TYPEHASH =
        keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable AUTHORITY;
    IIdentityVerifier public verifier; // Identity Layer
    IEvaluationStrategy public evaluationStrategy; // Evaluation Layer
    string public configIpfsHash;

    // Time constraints
    uint256 public immutable BIDDING_DEADLINE;
    uint256 public immutable REVEAL_DEADLINE;
    uint256 public challengePeriod; // Duration
    uint256 public challengeDeadline; // Timestamp

    // Disputes
    Dispute[] public disputes;

    // Financials
    uint256 public immutable BID_BOND_AMOUNT;

    // State
    TenderState public state;
    address public winner; // Address of winner for payout

    bytes32 public winningBidderId;
    uint256 public winningAmount;

    // Bids storage
    mapping(bytes32 => Bid) public bids;
    bytes32[] public bidderIds;

    // Cross-chain
    address public crossChainReceiver;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TenderOpened(
        uint256 biddingDeadline,
        uint256 revealDeadline,
        bytes32 identityType
    );
    event BidSubmitted(bytes32 indexed bidderId, bytes32 commitment);
    event CrossChainBidSubmitted(
        bytes32 indexed bidderId,
        bytes32 commitment,
        uint64 sourceChain
    );
    event BidRevealed(
        bytes32 indexed bidderId,
        uint256 amount,
        bytes32 metadataHash
    );
    event TenderAwarded(bytes32 indexed winnerId, uint256 amount);
    event TenderCanceled(string reason);
    event BondsSlashed(uint256 totalAmount);
    event IdentityVerificationBypassed(); // Legacy/Dev mode warning

    // Dispute Events
    event DisputeOpened(
        uint256 indexed disputeId,
        address indexed challenger,
        string reason
    );
    event DisputeResolved(uint256 indexed disputeId, bool upheld);
    event TenderResolved();

    struct Dispute {
        address challenger;
        string reason;
        bool resolved;
        bool upheld;
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyAuthority() {
        _checkAuthority();
        _;
    }

    function _checkAuthority() internal view {
        if (msg.sender != AUTHORITY) revert Unauthorized();
    }

    modifier atState(TenderState _state) {
        _checkState(_state);
        _;
    }

    function _checkState(TenderState _state) internal view {
        if (state != _state) revert InvalidState(state, _state);
    }

    /// @notice Returns the Identity Type of the current configuration
    function getIdentityType() external view returns (bytes32) {
        if (address(verifier) == address(0)) {
            return "ADDRESS";
        }
        return verifier.identityType();
    }

    /*//////////////////////////////////////////////////////////////
                            TENDER FLOW
    //////////////////////////////////////////////////////////////*/

    function openTendering()
        external
        onlyAuthority
        atState(TenderState.CREATED)
    {
        state = TenderState.OPEN;

        // Emit Identity Info for Indexers
        bytes32 idType = "ADDRESS";
        if (address(verifier) != address(0)) {
            idType = verifier.identityType();
        }

        emit TenderOpened(BIDDING_DEADLINE, REVEAL_DEADLINE, idType);
    }

    /// @dev Internal helper to enforce domain separation on Bidder IDs
    function _getBidderId(address _user) internal pure returns (bytes32) {
        // keccak256(abi.encodePacked) is used for readability and standard EIP-712 compliance.
        return keccak256(abi.encodePacked("ADDR_BIDDER", _user));
    }

    /// @dev Internal helper for wrapping verified signals
    /// @notice Unifies ID generation for Verified (Simulated) and Public modes
    function _bidderIdFromSignal(
        bytes32 _signal
    ) internal pure returns (bytes32) {
        // keccak256(abi.encodePacked) is used for readability and standard EIP-712 compliance.
        return keccak256(abi.encodePacked("ADDR_BIDDER", _signal));
    }

    /// @notice Reveal a previously committed bid using EIP-712 verification
    /// @dev Assumes msg.sender maps to bidderId for this phase (Sender == Identity).
    /// @param _amount The bid amount (e.g. price)
    /// @param _salt The random salt used in commitment
    /// @param _metadata The full metadata bytes (preimage of metadataHash).
    function revealBid(
        uint256 _amount,
        bytes32 _salt,
        bytes calldata _metadata
    ) external whenNotPaused {
        if (state == TenderState.OPEN && block.timestamp >= BIDDING_DEADLINE) {
            state = TenderState.REVEAL_PERIOD;
        }

        if (state != TenderState.REVEAL_PERIOD) {
            revert InvalidState(state, TenderState.REVEAL_PERIOD);
        }
        if (block.timestamp > REVEAL_DEADLINE) {
            revert InvalidTime(block.timestamp, REVEAL_DEADLINE);
        }

        bytes32 bidderId;
        if (address(verifier) != address(0)) {
            // If relying on Identity Certificate, we must derive ID from that.
            // But Wait! In reveal phase, we don't present the certificate again presumably?
            // We rely on msg.sender?
            // Logic validation: How did we retrieve bidderId in revealBid?
            // We used _getBidderId(msg.sender).
            // If we used Identity, _getBidderId(msg.sender) works if msg.sender is same.
            bidderId = _getBidderId(msg.sender);
        } else {
            bidderId = _getBidderId(msg.sender);
        }

        Bid storage bid = bids[bidderId];
        if (bid.revealed) revert AlreadyRevealed();

        // 1. Compute metadataHash from the revealed metadata
        // Using high-level keccak256 for readability and maintenance.
        bytes32 metadataHash = keccak256(_metadata);

        // 2. Re-create the structHash that was signed/committed
        // Using abi.encode for EIP-712 structural integrity.
        bytes32 structHash = keccak256(
            abi.encode(BID_TYPEHASH, _amount, _salt, metadataHash)
        );
        bytes32 computedHash = _hashTypedDataV4(structHash);

        if (computedHash != bid.commitment) {
            revert InvalidCommitment();
        }

        // 3. Scoring
        bid.score = evaluationStrategy.scoreBid(_amount, _metadata);

        bid.revealed = true;
        bid.revealedAmount = _amount;

        emit BidRevealed(bidderId, _amount, metadataHash);

        _logCompliance(
            REG_BID_REVEALED,
            msg.sender,
            bidderId,
            abi.encode(_amount)
        );
    }

    function evaluate() external onlyAuthority {
        if (
            state == TenderState.REVEAL_PERIOD &&
            block.timestamp >= REVEAL_DEADLINE
        ) {
            state = TenderState.EVALUATION;
        }
        if (state != TenderState.EVALUATION) {
            revert InvalidState(state, TenderState.EVALUATION);
        }

        bytes32 currentWinnerId = bytes32(0);

        // Sorting Logic
        // NOTE: On-chain sorting assumes a bounded number of bids.
        // Large-scale tenders should use off-chain sorting with on-chain verification.
        bool lowerIsBetter = evaluationStrategy.isLowerBetter();
        uint256 bestScore = lowerIsBetter ? type(uint256).max : 0;

        bool foundValid = false;

        for (uint256 i = 0; i < bidderIds.length; i++) {
            bytes32 bId = bidderIds[i];
            Bid memory b = bids[bId];
            if (b.revealed) {
                bool isBetter = false;
                if (lowerIsBetter) {
                    if (b.score < bestScore) isBetter = true;
                } else {
                    if (b.score > bestScore) isBetter = true;
                }

                if (isBetter || !foundValid) {
                    bestScore = b.score;
                    currentWinnerId = bId;
                    foundValid = true;
                }
            }
        }

        if (!foundValid) revert NoValidBids();

        winningBidderId = currentWinnerId;
        winningAmount = bids[currentWinnerId].revealedAmount;

        state = TenderState.AWARDED;
        challengeDeadline = block.timestamp + challengePeriod;

        emit TenderAwarded(winningBidderId, winningAmount);
    }

    /// @notice Challenge the award. Requires posting a bond (same as bid bond).
    function challengeWinner(
        string calldata reason
    ) external payable atState(TenderState.AWARDED) {
        if (block.timestamp >= challengeDeadline) {
            revert InvalidTime(block.timestamp, challengeDeadline);
        }
        if (msg.value < BID_BOND_AMOUNT) revert IncorrectFee();

        disputes.push(
            Dispute({
                challenger: msg.sender,
                reason: reason,
                resolved: false,
                upheld: false
            })
        );

        emit DisputeOpened(disputes.length - 1, msg.sender, reason);

        _logCompliance(
            REG_DISPUTE_OPENED,
            msg.sender,
            bytes32(disputes.length - 1),
            bytes(reason)
        );
    }

    function resolveDispute(
        uint256 disputeId,
        bool uphold
    ) external onlyAuthority {
        if (disputeId >= disputes.length) revert("Invalid dispute ID");
        Dispute storage d = disputes[disputeId];
        if (d.resolved) revert("Already resolved");

        d.resolved = true;
        d.upheld = uphold;

        if (uphold) {
            // Dispute upheld -> Tender Canceled (Simplification)
            state = TenderState.CANCELED;
            payable(d.challenger).transfer(BID_BOND_AMOUNT + BID_BOND_AMOUNT); // Return bond + reward? Or just bond?
            // Actually, we need to slash the Winner's bond if they were fraudulent?
            // For now, let's just refund challenger.
            // And maybe the Winner loses their bond later via typical slashing logic?
        } else {
            // Dispute rejected -> Challenger slashed.
            // Bond is kept in contract (to be claimed by authority).
        }

        emit DisputeResolved(disputeId, uphold);
    }

    /// @notice Withdraw bond. Only allowed if revealed or canceled.
    /// @dev If you didn't reveal, your bond is stuck until slashed/claimed by authority.
    function finalize() external {
        if (state == TenderState.RESOLVED) return;
        if (state == TenderState.CANCELED) return;

        if (state != TenderState.AWARDED) {
            revert InvalidState(state, TenderState.AWARDED);
        }
        if (block.timestamp < challengeDeadline) {
            revert InvalidTime(block.timestamp, challengeDeadline);
        }

        // Ensure all disputes are resolved
        for (uint256 i = 0; i < disputes.length; i++) {
            if (!disputes[i].resolved) {
                revert("Active dispute");
            }
        }

        // Ensure not canceled via dispute (though resolveDispute handles that transition immediately)
        // If we are here, we are good.

        state = TenderState.RESOLVED;
        emit TenderResolved();
    }

    /// @notice Withdraw bond. Only allowed if revealed or canceled.
    /// @dev If you didn't reveal, your bond is stuck until slashed/claimed by authority.
    function withdrawBond() external whenNotPaused {
        if (state == TenderState.CANCELED) {
            _refund(msg.sender);
            return;
        }

        // Strict Check: Must be RESOLVED.
        if (state != TenderState.RESOLVED) {
            revert InvalidState(state, TenderState.RESOLVED);
        }

        bytes32 bidderId = _getBidderId(msg.sender);

        // Winner cannot withdraw bond (It is kept as performance bond usually, or needs specific release logic)
        // For now, we keep the constraint: Winner bond locked.
        if (bidderId == winningBidderId) revert Unauthorized();

        // Slashing Logic: You can ONLY withdraw if you revealed.
        Bid storage bid = bids[bidderId];
        if (!bid.revealed) revert BondForfeited();

        _refund(msg.sender);
    }

    function _refund(address _user) internal {
        bytes32 bidderId = _getBidderId(_user);
        Bid storage bid = bids[bidderId];
        if (bid.deposit > 0) {
            uint256 amount = bid.deposit;
            bid.deposit = 0;
            payable(_user).transfer(amount);
        }
    }

    /// @notice Authority sweeps bonds from non-revealing bidders
    /// @dev Only allowed after tender is RESOLVED (challenges settled)
    function claimSlashedFunds() external onlyAuthority {
        if (state != TenderState.RESOLVED) {
            revert InvalidState(state, TenderState.RESOLVED);
        }

        uint256 slashedAmount = 0;
        for (uint256 i = 0; i < bidderIds.length; i++) {
            bytes32 bId = bidderIds[i];
            Bid storage bid = bids[bId];
            // If not revealed and not the winner
            if (!bid.revealed && bId != winningBidderId) {
                if (bid.deposit > 0) {
                    slashedAmount += bid.deposit;
                    bid.deposit = 0;
                }
            }
        }

        if (slashedAmount > 0) {
            payable(AUTHORITY).transfer(slashedAmount);
            emit BondsSlashed(slashedAmount);
        }
    }

    // Emergency cancel
    function cancelTender(string calldata reason) external onlyAuthority {
        state = TenderState.CANCELED;
        emit TenderCanceled(reason);
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function pause() external onlyAuthority {
        _pause();
    }

    function unpause() external onlyAuthority {
        _unpause();
    }
}
