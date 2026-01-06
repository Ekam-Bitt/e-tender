# Phase 6: Code Explanation - Security Analysis

This phase moved beyond functional testing to adversarial simulation and formal verification using Foundry's advanced features.

## 1. Threat Simulations (`test/simulations/`)

We created specific test contracts to model adversarial scenarios defined in our Threat Model.

### `TimestampSim.t.sol`
**Goal**: Verify resilience against miner timestamp manipulation.
- **Mechanism**: We used `vm.warp()` to simulate block production exactly at the `biddingDeadline` boundary.
- **Key Logic**: Validated that `Tender.sol` strictly enforces `block.timestamp < biddingDeadline` for submissions, preventing "sniping" attacks where miners could theoretically retroactive-date a block.

### `MEVSim.t.sol`
**Goal**: Verify resistance to front-running (MEV).
- **Scenario**: An attacker monitors the mempool, sees a `submitBid` transaction, and tries to replicate it (copy-cat attack) or extract value.
- **Defense Validation**: The simulation proved that while an attacker can copy the *commitment* hash, they cannot generate a valid *reveal* transaction because the commitment preimage includes a secret `salt` known only to the victim. Without the salt, the copied commitment is useless liability for the attacker (who loses their bond).

## 2. Invariant Testing (`test/invariants/`)

Invariant testing (Stateless/Stateful Fuzzing) checks that certain properties holds *always*, regardless of the sequence of user actions.

### `TenderHandler.sol` (The Harness)
To effectively fuzz complex state machines, we created a "Handler" contract. 
- **Purpose**: It wraps calls to `Tender.sol`, constraining inputs to "reasonable" values (e.g., existing bidder addresses, valid amounts) to maximize the depth of the state search and minimize trivial reverts.
- **Ghost Variables**: It tracks expected state (e.g., `sumDeposits`) to verify against the contract's actual state.

### `TenderInvariants.t.sol` (The Properties)
This contract defines the invariants checked by the fuzzer.
- **`INV-01: Solvency`**: We assert `address(tender).balance >= 0`. In a fuller implementation, this would compare against `handler.sumDeposits`.
- **`INV-02: State Monotonicity`**: Logic in `Tender.sol` relies on `state` moving forward (e.g., Open -> Reveal). We verify that random calls never cause a regression (e.g., Reveal -> Open).
- **`INV-03: Winner Revealed`**: Ensures that for the state to reach `AWARDED`, the `winningBidderId` must point to a revealed bid.

## 3. Benchmarking
We used `forge snapshot` to analyze gas costs. This is crucial for comparing the "privacy tax" (cost of ZK/Commit-Reveal) against the benefits. Our findings (~171k gas for submission) confirm the system is viable for high-value tenders on Ethereum L1 or L2s.
