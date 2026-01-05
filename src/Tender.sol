// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IIdentityVerifier.sol";

/**
 * @title Tender
 * @notice Represents a single tender lifecycle from creation to award.
 * @dev Implements a Commit-Reveal scheme using EIP-712 for typed structural hashing.
 */
contract Tender is EIP712 {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error InvalidState(TenderState current, TenderState expected);
    error InvalidTime(uint256 current, uint256 deadline);
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
        CANCELED
    }

    struct Bid {
        bytes32 commitment; // EIP-712 Hash
        uint256 revealedAmount;
        uint256 deposit;
        uint64 timestamp;
        bool revealed;
    }

    bytes32 private constant BID_TYPEHASH = keccak256("Bid(uint256 amount,bytes32 salt,bytes32 metadataHash)");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    address public immutable authority;
    IIdentityVerifier public verifier; // Identity Layer
    string public configIpfsHash; 
    
    // Time constraints
    uint256 public immutable biddingDeadline;
    uint256 public immutable revealDeadline;
    
    // Financials
    uint256 public immutable bidBondAmount;
    
    // State
    TenderState public state;
    address public winner; // Address of winner for payout (still needs an address)
    // OR better: winnerBidderId?
    // User requirement: "msg.sender still pays gas".
    // "One bid per bidderId"
    // We can keep `address public winner` if we assume the bidderId maps to an address eventually, 
    // OR winner is just the address that successfully claimed the winning bid.
    // Let's keep `address winner` as the "payout destination" or "controller".
    // Actually, `evaluate` sets `winner`. If Bids are keyed by ID, we need to store who owns that ID? 
    // Or just store the winning `bidderId`.
    // Let's stick to: we map `bytes32 bidderId => Bid`.
    // We also track `address[] public bidders`? No, `bytes32[] public bidderIds`.
    
    bytes32 public winningBidderId;
    uint256 public winningAmount;

    // Bids storage
    mapping(bytes32 => Bid) public bids;
    bytes32[] public bidderIds;
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TenderOpened(uint256 biddingDeadline, uint256 revealDeadline, bytes32 identityType);
    event BidSubmitted(bytes32 indexed bidderId, bytes32 commitment);
    event BidRevealed(bytes32 indexed bidderId, uint256 amount, bytes32 metadataHash);
    event TenderAwarded(bytes32 indexed winnerId, uint256 amount);
    event TenderCanceled(string reason);
    event BondsSlashed(uint256 totalAmount);
    event IdentityVerificationBypassed(); // Legacy/Dev mode warning

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyAuthority() {
        if (msg.sender != authority) revert Unauthorized();
        _;
    }

    modifier atState(TenderState _state) {
        if (state != _state) revert InvalidState(state, _state);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _authority,
        address _verifier,
        string memory _configIpfsHash,
        uint256 _biddingTime,
        uint256 _revealTime,
        uint256 _bidBondAmount
    ) EIP712("Tender", "1") {
        authority = _authority;
        verifier = IIdentityVerifier(_verifier);
        configIpfsHash = _configIpfsHash;
        bidBondAmount = _bidBondAmount;
        
        if (_verifier != address(0)) {
            // IdentityType comes from Verifier (e.g. "ISSUER_SIGNATURE")
             try IIdentityVerifier(_verifier).identityType() returns (bytes32 _type) {
                 // Optimization: We could store this. 
                 // But since it's pure, we can just read it dynamically or assume it's set.
                 // Let's assume we want to log it?
                 // Actually, let's just leave it for external introspection via the verifier address.
             } catch {
                 // Ignore if not implemented (safety)
             }
        }
        
        biddingDeadline = block.timestamp + _biddingTime;
        revealDeadline = block.timestamp + _biddingTime + _revealTime;
        
        state = TenderState.CREATED;
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
    
    function openTendering() external onlyAuthority atState(TenderState.CREATED) {
        state = TenderState.OPEN;
        
        // Emit Identity Info for Indexers
        bytes32 idType = "ADDRESS";
        if (address(verifier) != address(0)) {
            idType = verifier.identityType();
        }
        
        emit TenderOpened(biddingDeadline, revealDeadline, idType);
    }
    
    /// @dev Internal helper to enforce domain separation on Bidder IDs
    function _getBidderId(address _user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ADDR_BIDDER", _user));
    }
    
    /// @dev Internal helper for wrapping verified signals
    /// @notice Unifies ID generation for Verified (Simulated) and Public modes
    function _bidderIdFromSignal(bytes32 _signal) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ADDR_BIDDER", _signal));
    }

    /// @notice Submit a sealed bid (commitment) with Identity Proof
    /// @param _commitment EIP-712 compatible hash of the bid data
    /// @param _identityProof Proof for IIdentityVerifier (Signature or ZK Proof)
    /// @param _publicSignals Signals for Verifier (e.g. [userAddress] or [nullifier])
    function submitBid(
        bytes32 _commitment, 
        bytes calldata _identityProof,
        bytes32[] calldata _publicSignals
    ) external payable atState(TenderState.OPEN) {
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

        if (block.timestamp >= biddingDeadline) revert InvalidTime(block.timestamp, biddingDeadline);
        if (msg.value < bidBondAmount) revert IncorrectFee();
        if (bids[bidderId].commitment != bytes32(0)) revert BidAlreadyExists();

        bids[bidderId] = Bid({
            commitment: _commitment,
            revealedAmount: 0,
            deposit: msg.value,
            timestamp: uint64(block.timestamp),
            revealed: false
        });
        bidderIds.push(bidderId);

        emit BidSubmitted(bidderId, _commitment);
    }

    /// @notice Reveal a previously committed bid using EIP-712 verification
    /// @dev Assumes msg.sender maps to bidderId for this phase (Sender == Identity).
    function revealBid(uint256 _amount, bytes32 _salt, bytes32 _metadataHash) external {
        if (state == TenderState.OPEN && block.timestamp >= biddingDeadline) {
            state = TenderState.REVEAL_PERIOD;
        }

        if (state != TenderState.REVEAL_PERIOD) revert InvalidState(state, TenderState.REVEAL_PERIOD);
        if (block.timestamp >= revealDeadline) revert InvalidTime(block.timestamp, revealDeadline);

        // Derive ID from sender using Domain Separation
        bytes32 bidderId = _getBidderId(msg.sender);

        Bid storage bid = bids[bidderId];
        if (bid.revealed) revert AlreadyRevealed();
        
        // EIP-712 Structural Hash Verification
        bytes32 structHash = keccak256(abi.encode(BID_TYPEHASH, _amount, _salt, _metadataHash));
        bytes32 computedHash = _hashTypedDataV4(structHash);

        if (computedHash != bid.commitment) {
            revert InvalidCommitment();
        }

        bid.revealed = true;
        bid.revealedAmount = _amount;

        emit BidRevealed(bidderId, _amount, _metadataHash);
    }

    function evaluate() external onlyAuthority {
        if (state == TenderState.REVEAL_PERIOD && block.timestamp >= revealDeadline) {
            state = TenderState.EVALUATION;
        }
        if (state != TenderState.EVALUATION) revert InvalidState(state, TenderState.EVALUATION);

        bytes32 currentWinnerId = bytes32(0);
        uint256 lowestBid = type(uint256).max;

        bool foundValid = false;

        for (uint256 i = 0; i < bidderIds.length; i++) {
            bytes32 bId = bidderIds[i];
            Bid memory b = bids[bId];
            if (b.revealed) {
                if (b.revealedAmount < lowestBid) {
                    lowestBid = b.revealedAmount;
                    currentWinnerId = bId;
                    foundValid = true;
                }
            }
            // Non-revealed bids are effectively ignored here (and slashed later)
        }

        if (!foundValid) revert NoValidBids();

        winningBidderId = currentWinnerId;
        winningAmount = lowestBid;
        
        state = TenderState.AWARDED;
        emit TenderAwarded(winningBidderId, winningAmount);
    }
    
    /// @notice Withdraw bond. Only allowed if revealed or canceled.
    /// @dev If you didn't reveal, your bond is stuck until slashed/claimed by authority.
    function withdrawBond() external {
        if (state == TenderState.CANCELED) {
            // Allow everyone (who is the sender?)
            _refund(msg.sender);
            return;
        }

        if (state != TenderState.AWARDED) revert InvalidState(state, TenderState.AWARDED);
        
        // Derive ID
        bytes32 bidderId = _getBidderId(msg.sender);
        
        // Winner cannot withdraw yet
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
    function claimSlashedFunds() external onlyAuthority {
        if (state != TenderState.AWARDED) revert InvalidState(state, TenderState.AWARDED);
        
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
            payable(authority).transfer(slashedAmount);
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
}
