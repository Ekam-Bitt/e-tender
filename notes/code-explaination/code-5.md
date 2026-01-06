# Phase 5: Code Explanation

This document details the technical implementation of Governance, Disputes, and Upgradability features added in Phase 5.

## 1. Governance & Disputes (`contracts/Tender.sol`)

### State Management
We introduced a `RESOLVED` state and `challengePeriod` parameters.
```solidity
    enum TenderState { ..., RESOLVED, CANCELED }
    
    struct Dispute {
        address challenger;
        string reason;
        bool resolved;
        bool upheld;
    }
    
    Dispute[] public disputes;
    uint256 public challengeDeadline;
    uint256 public challengePeriod;
```

### Challenge Logic
The `challengeWinner` function allows anyone to challenge the award by posting a bond.
- **Prerequisites**: Tender must be in `AWARDED` state, and within the `challengeDeadline`.
- **Bonding**: Takes `msg.value` equal to `bidBondAmount`.
- **Storage**: Pushes a new `Dispute` to the array.

### Resolution Logic
The `resolveDispute` function empowers the `authority` to adjudicate.
- **Upheld**: Finds the challenge valid. The tender moves to `CANCELED` state. The challenger receives their bond back + reward (contracts sends `2 * bond`).
- **Rejected**: Finds the challenge frivolous. The challenger's bond is effectively slashed (kept in contract).

### Circuit Breakers (Pausable)
We inherited OpenZeppelin's `Pausable`.
- `pause()` / `unpause()`: Only callable by `authority`.
- `whenNotPaused` modifier: Applied to `submitBid`, `revealBid`, and `withdrawBond` to prevent interaction during emergencies.

## 2. Factory Upgradability (`contracts/TenderFactory.sol`)

### UUPS Pattern
We utilized the Universal Upgradeable Proxy Standard (UUPS) for `TenderFactory`. This allows us to upgrade the factory logic (e.g., how tenders are created or tracked) without changing the factory's address.

- **Inheritance**: `Initializable`, `UUPSUpgradeable`, `OwnableUpgradeable`.
- **Storage**: Storage variables must be append-only to avoid collisions during upgrades.
- **Proxy**: The deployed contract is an `ERC1967Proxy` that delegates calls to the `TenderFactory` implementation.

### Implementation Details
- **Constructor**: Disabled initializers to prevent direct initialization of the implementation contract.
- **Initialize**: The `initialize()` function sets the owner.
- **Authorize Upgrade**: `_authorizeUpgrade` ensures only the owner can upgrade the contract.

## 3. Testing Dispute Logic (`test/Disputes.t.sol`)

The test suite simulates the entire lifecycle to reach the `AWARDED` state and then tests dispute edge cases.

### Key Test: `setUp`
We reconstructed the `setUp` carefully to mimic EIP-712 signing manually, ensuring we could generate valid bids and reveals to reach the `AWARDED` state programmatically.

### Key Test: `testValidChallenge`
1. **Challenge**: `bidder2` calls `challengeWinner` with bond.
2. **Resolve**: `authority` calls `resolveDispute(0, true)`.
3. **Verify**:
   - State is `CANCELED`.
   - `bidder2` balance increases by `2 * bond`.

### Debugging Note
We encountered an `InvalidCommitment` error during testing due to `vm.prank` usage. When using helper functions that make external calls (like `tender.getDomainSeparator()`) inside a test, they consume the `vm.prank`. We fixed this by moving `vm.prank` strictly before the target `submitBid` call.
