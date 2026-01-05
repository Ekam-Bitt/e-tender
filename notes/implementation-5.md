# Phase 5: Governance, Disputes & Upgradability

## Goal
Add real-world resilience through Dispute Resolution mechanisms and Factory Upgradability.

## User Requirements
- **Disputes**: Challenge window, Bonded disputes, Slashing.
- **Governance**: DAO oversight (Assumed via Authority/Timelock).
- **Upgradability**: Factory upgradable (UUPS), Individual tenders immutable.

## Proposed Architecture

### 1. Dispute Resolution (`Tender.sol`)
Refactor the lifecycle to include a challenge period after awarding.

**New Enums/State**:
- `TenderState.RESOLVED` (Final state after challenge period).
- `mapping(bytes32 => Dispute) disputes`.
- `uint256 challengeDeadline`.

**New Functions**:
- `challengeWinner(string reason)`:
    - Requirements: `state == AWARDED`, `msg.value == bond`.
    - Effect: Emits `DisputeOpened`.
    - Note: Does ONLY the winner get challenged? Or the whole result? Usually challenging the *Award*.
- `resolveDispute(bool upholdChallenge)`:
    - Role: `onlyAuthority` (Governance/DAO).
    - If `uphold`: Winner is slashed (or unmarked), process re-evaluation? Or just cancel?
    - Simplification: If challenge upheld, Tender -> `CANCELED` (or specific `DISPUTED` state needing manual intervention).
    - If rejected: Challenger bond slashed.

**Withdrawal Logic**:
- Winner can ONLY withdraw winning funds after `challengeDeadline` serves WITHOUT active disputes.

### 2. Upgradability (`TenderFactory.sol`)
Refactor `TenderFactory` to use UUPS Proxy pattern.
- Allows the DAO to upgrade the Factory to deploy *new* versions of `Tender` contracts (e.g. v2) without changing the Factory address.
- `Tender` contracts themselves remain immutable (Trust Minimization).

### 3. Governance Circuit Breakers
- Add `pause()` / `unpause()` to `Tender.sol` (controversial for immutable tenders, but standard for enterprise safety).
- Role: `onlyAuthority`.
- Effect: Stops `submitBid`, `revealBid`, `withdrawBond`.

## Verification Plan
1. **TestDisputes.t.sol**:
    - Challenge valid winner (Frivolous) -> Challenger Slashed.
    - Challenge invalid winner (Valid) -> Winner Slashed/Tender Canceled.
2. **TestUpgrades.t.sol**:
    - Deploy Factory v1.
    - Upgrade to Factory v2 (e.g. changing fee or logic).
    - Verify state preservation.

## Migration Steps
1. Modify `Tender.sol` state machine.
2. Implement Dispute logic.
3. Rewrite `TenderFactory.sol` as UUPS.
4. Add Tests.
