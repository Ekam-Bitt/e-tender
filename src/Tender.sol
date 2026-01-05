// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
    string public configIpfsHash; 
    
    // Time constraints
    uint256 public immutable biddingDeadline;
    uint256 public immutable revealDeadline;
    
    // Financials
    uint256 public immutable bidBondAmount;
    
    // State
    TenderState public state;
    address public winner;
    uint256 public winningAmount;

    // Bids storage
    mapping(address => Bid) public bids;
    address[] public bidders;
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TenderOpened(uint256 biddingDeadline, uint256 revealDeadline);
    event BidSubmitted(address indexed bidder, bytes32 commitment);
    event BidRevealed(address indexed bidder, uint256 amount, bytes32 metadataHash);
    event TenderAwarded(address indexed winner, uint256 amount);
    event TenderCanceled(string reason);
    event BondsSlashed(uint256 totalAmount);

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
        string memory _configIpfsHash,
        uint256 _biddingTime,
        uint256 _revealTime,
        uint256 _bidBondAmount
    ) EIP712("Tender", "1") {
        authority = _authority;
        configIpfsHash = _configIpfsHash;
        bidBondAmount = _bidBondAmount;
        
        biddingDeadline = block.timestamp + _biddingTime;
        revealDeadline = block.timestamp + _biddingTime + _revealTime;
        
        state = TenderState.CREATED;
    }

    /*//////////////////////////////////////////////////////////////
                            TENDER FLOW
    //////////////////////////////////////////////////////////////*/
    
    function openTendering() external onlyAuthority atState(TenderState.CREATED) {
        state = TenderState.OPEN;
        emit TenderOpened(biddingDeadline, revealDeadline);
    }

    /// @notice Submit a sealed bid (commitment)
    /// @param _commitment EIP-712 compatible hash of the bid data
    function submitBid(bytes32 _commitment) external payable atState(TenderState.OPEN) {
        if (block.timestamp >= biddingDeadline) revert InvalidTime(block.timestamp, biddingDeadline);
        if (msg.value < bidBondAmount) revert IncorrectFee();
        if (bids[msg.sender].commitment != bytes32(0)) revert BidAlreadyExists();

        bids[msg.sender] = Bid({
            commitment: _commitment,
            revealedAmount: 0,
            deposit: msg.value,
            timestamp: uint64(block.timestamp),
            revealed: false
        });
        bidders.push(msg.sender);

        emit BidSubmitted(msg.sender, _commitment);
    }

    /// @notice Reveal a previously committed bid using EIP-712 verification
    function revealBid(uint256 _amount, bytes32 _salt, bytes32 _metadataHash) external {
        if (state == TenderState.OPEN && block.timestamp >= biddingDeadline) {
            state = TenderState.REVEAL_PERIOD;
        }

        if (state != TenderState.REVEAL_PERIOD) revert InvalidState(state, TenderState.REVEAL_PERIOD);
        if (block.timestamp >= revealDeadline) revert InvalidTime(block.timestamp, revealDeadline);

        Bid storage bid = bids[msg.sender];
        if (bid.revealed) revert AlreadyRevealed();
        
        // EIP-712 Structural Hash Verification
        bytes32 structHash = keccak256(abi.encode(BID_TYPEHASH, _amount, _salt, _metadataHash));
        bytes32 computedHash = _hashTypedDataV4(structHash);

        if (computedHash != bid.commitment) {
            revert InvalidCommitment();
        }

        bid.revealed = true;
        bid.revealedAmount = _amount;

        emit BidRevealed(msg.sender, _amount, _metadataHash);
    }

    function evaluate() external onlyAuthority {
        if (state == TenderState.REVEAL_PERIOD && block.timestamp >= revealDeadline) {
            state = TenderState.EVALUATION;
        }
        if (state != TenderState.EVALUATION) revert InvalidState(state, TenderState.EVALUATION);

        address currentWinner = address(0);
        uint256 lowestBid = type(uint256).max;

        bool foundValid = false;

        for (uint256 i = 0; i < bidders.length; i++) {
            Bid memory b = bids[bidders[i]];
            if (b.revealed) {
                if (b.revealedAmount < lowestBid) {
                    lowestBid = b.revealedAmount;
                    currentWinner = bidders[i];
                    foundValid = true;
                }
            }
            // Non-revealed bids are effectively ignored here (and slashed later)
        }

        if (!foundValid) revert NoValidBids();

        winner = currentWinner;
        winningAmount = lowestBid;
        
        state = TenderState.AWARDED;
        emit TenderAwarded(winner, winningAmount);
    }
    
    /// @notice Withdraw bond. Only allowed if revealed or canceled.
    /// @dev If you didn't reveal, your bond is stuck until slashed/claimed by authority.
    function withdrawBond() external {
        if (state == TenderState.CANCELED) {
            // Allow everyone
            _refund(msg.sender);
            return;
        }

        if (state != TenderState.AWARDED) revert InvalidState(state, TenderState.AWARDED);
        
        // Winner cannot withdraw yet
        if (msg.sender == winner) revert Unauthorized();

        // Slashing Logic: You can ONLY withdraw if you revealed.
        Bid storage bid = bids[msg.sender];
        if (!bid.revealed) revert BondForfeited();

        _refund(msg.sender);
    }
    
    function _refund(address _user) internal {
        Bid storage bid = bids[_user];
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
        for (uint256 i = 0; i < bidders.length; i++) {
            Bid storage bid = bids[bidders[i]];
            // If not revealed and not the winner (winner check redundant if winner implies revealed, but safe)
            if (!bid.revealed && bidders[i] != winner) {
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
