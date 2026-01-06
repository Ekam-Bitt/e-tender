# Phase 8: Code Explanation - Deployment

## Scripting with Foundry (`script/Deploy.s.sol`)

Foundry scripts allow us to write deployment logic in Solidity, utilizing the same cheatcodes (`vm`) as tests but with `broadcast` capabilities.

### 1. `vm.startBroadcast(deployerPrivateKey)`
This cheatcode creates transactions that can be broadcast to the RPC. All `new` calls and external function calls after this line are recorded as real transactions.

### 2. UUPS Proxy Pattern
```solidity
TenderFactory implementation = new TenderFactory();
bytes memory initData = abi.encodeCall(TenderFactory.initialize, ());
ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
```
- **Why**: We deploy the logic once (`implementation`). The `proxy` holds the storage (owner, tender lists).
- **Initialize**: The `initData` ensures `initialize()` is called ATOMICALLY during proxy construction, preventing front-running attacks on initialization.

### 3. Environment Management
```solidity
uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
```
- We avoid hardcoding keys. Foundry reads from `.env` or system variables, keeping secrets safe.

### 4. Modular Infrastructure
The script separates core deployment (Factory) from peripheral deployment (Strategies), allowing modular updates or partial deployments in the future.
