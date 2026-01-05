# Phase 5: Governance, Disputes & Upgradability Walkthrough

## Overview
This phase focused on enhancing the robustness of the e-tendering system by introducing a governance layer for dispute resolution and facilitating upgradability for the factory contract.

## Changes Implemented

### 1. Dispute Resolution Mechanism (`Tender.sol`)
- **Challenge Period**: A window of time after the tender is awarded during which users can challenge the winner.
- **Bonded Challenges**: Challengers must post a bond equal to the bid bond to open a dispute.
- **Resolution**: The `Authority` can resolve disputes.
  - **Upheld**: The tender is canceled, and the challenger is rewarded.
  - **Rejected**: The challenger's bond is slashed.
- **Withdrawal Locks**: Bond withdrawals are blocked during the challenge period and if any active disputes exist.

### 2. Governance Circuit Breakers (`Tender.sol`)
- **Pausability**: Integrated `Pausable` to allow the authority to pause critical functions (`submitBid`, `revealBid`, `withdrawBond`) in emergencies.

### 3. Upgradability (`TenderFactory.sol`)
- **UUPS Pattern**: Refactored `TenderFactory` to use the Universal Upgradeable Proxy Standard (UUPS).
- **Versioning**: Using `Initializable` to manage versioning.
- **Owner-only Upgrades**: Only the owner can authorize contract upgrades.
- **Immutable Tenders**: While the factory is upgradeable, individual `Tender` contracts remain immutable for security and trust.

## Verification

### Automated Tests
We implemented a new test suite `test/Disputes.t.sol` covering the following scenarios:
- `testChallengePeriod_BlockingWithdrawal`: Ensures no one (including winner) can withdraw bonds during the challenge period.
- `testFrivolousChallenge`: Verifies that invalid challenges result in bond slashing for the challenger.
- `testValidChallenge`: Verifies that valid challenges lead to tender cancellation and challenger reward.
- `testWinnerWithdrawal_AfterChallengePeriod`: Confirms the winner can only withdraw after the challenge period ends without disputes.

Run tests with:
```bash
forge test
```
Result:
```
Ran 4 test suites: 15 tests passed, 0 failed.
```

## Key Learnings
- **Testing Proxies**: Deploying UUPS proxies in Foundry requires deploying the implementation, then the `ERC1967Proxy` pointing to it, and initializing via the proxy.
- **Prank Management**: `vm.prank` only applies to the *next* call. Helper functions making external calls (like fetching domain separators) will consume the prank if placed incorrectly.

## Next Steps
- Phase 6: Deployment scripts and Audit preparation.
