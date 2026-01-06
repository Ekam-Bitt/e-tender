# Phase 8: Implementation Plan

## Overview
We are in the final stretch. We will create a robust `Deploy.s.sol` script using Foundry's scripting capabilities to ensure reproducible deployments.

## 1. Deployment Script
- **Contract**: `Deploy.s.sol`
- **Actions**:
    1. `vm.startBroadcast` (using private key from env).
    2. Deploy `TenderFactory` implementation.
    3. Deploy `ERC1967Proxy`.
    4. Initialize Protocol.
    5. Log addresses.

## 2. Final Cleanups
- Run `forge fmt`.
- Ensure all tests pass one last time.

## Next Steps
- Write `script/Deploy.s.sol`.
- Run deployment simulation.
