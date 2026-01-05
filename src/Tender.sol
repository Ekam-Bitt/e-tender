// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Tender
 * @notice Represents a single tender lifecycle from creation to award.
 * @dev Implements a Commit-Reveal scheme for sealed bids.
 */
contract Tender {
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
        bytes32 commitment; // Hash(amount, salt)
        uint256 revealedAmount;
        uint256 deposit;
        uint64 timestamp;
        bool revealed;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public immutable authority;
    string public configIpfsHash; // CID for tender specs
    
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
    event BidRevealed(address indexed bidder, uint256 amount);
    event TenderAwarded(address indexed winner, uint256 amount);
    event TenderCanceled(string reason);

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
    ) {
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
    
    /// @notice Opens the tender for bidding
    function openTendering() external onlyAuthority atState(TenderState.CREATED) {
        state = TenderState.OPEN;
        emit TenderOpened(biddingDeadline, revealDeadline);
    }

    /// @notice Submit a sealed bid (commitment)
    /// @param _commitment Keccak256 hash of (amount, salt)
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

    /// @notice Reveal a previously committed bid
    /// @param _amount The actual bid amount
    /// @param _salt The random salt used in commitment
    function revealBid(uint256 _amount, bytes32 _salt) external {
        // Automatically transition state if deadlines passed
        if (state == TenderState.OPEN && block.timestamp >= biddingDeadline) {
            state = TenderState.REVEAL_PERIOD;
        }

        if (state != TenderState.REVEAL_PERIOD) revert InvalidState(state, TenderState.REVEAL_PERIOD);
        if (block.timestamp >= revealDeadline) revert InvalidTime(block.timestamp, revealDeadline);

        Bid storage bid = bids[msg.sender];
        if (bid.revealed) revert AlreadyRevealed();
        
        // Verify commitment: keccak256(abi.encodePacked(amount, salt))
        // Note: Using encodePacked for simple concatenation logic often used in commitments
        if (keccak256(abi.encodePacked(_amount, _salt)) != bid.commitment) {
            revert InvalidCommitment();
        }

        bid.revealed = true;
        bid.revealedAmount = _amount;

        emit BidRevealed(msg.sender, _amount);
    }

    /// @notice Evaluate bids and select the lowest valid bidder
    /// @dev Simple logic: Lowest Price Wins. Ties broken by timestamp (first to bid wins - wait, first to bid committed? or reveal? usually first commit if time trusted, but simple is first found).
    /// @dev Actually, minimizing on-chain sorting loop is key. For now, O(N) linear scan is acceptable for small N.
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
        }

        if (!foundValid) revert NoValidBids();

        winner = currentWinner;
        winningAmount = lowestBid;
        
        state = TenderState.AWARDED;
        emit TenderAwarded(winner, winningAmount);
    }
    
    /// @notice Losers can withdraw their bond. Winner has bond locked (or handled differently).
    /// @dev For this phase, we allow everyone except winner to withdraw. Winner verification is off-chain or next step.
    function withdrawBond() external {
        if (state != TenderState.AWARDED && state != TenderState.CANCELED) revert InvalidState(state, TenderState.AWARDED);
        
        // If canceled, everyone withdraws. If Awarded, winner cannot withdraw yet (placeholder logic).
        if (state == TenderState.AWARDED && msg.sender == winner) {
            revert Unauthorized(); // Winner bond stays as performance guarantee (simplified)
        }

        Bid storage bid = bids[msg.sender];
        if (bid.deposit > 0) {
            uint256 amount = bid.deposit;
            bid.deposit = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    // Emergency cancel
    function cancelTender(string calldata reason) external onlyAuthority {
        state = TenderState.CANCELED;
        emit TenderCanceled(reason);
    }
}
