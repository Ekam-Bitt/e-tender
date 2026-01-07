# Deployments

## Sepolia Testnet

| Property | Value |
|----------|-------|
| **Chain ID** | 11155111 |
| **Network** | Ethereum Sepolia Testnet |
| **Deployment Date** | 2026-01-07 |
| **Deployer** | `0x...` (see broadcast logs) |

### Contract Addresses

| Contract | Address | Etherscan |
|----------|---------|-----------|
| Halo2Verifier | `0x03Fa77170645Bd424D5e273a921D8b76CA1F57BD` | [View](https://sepolia.etherscan.io/address/0x03fa77170645bd424d5e273a921d8b76ca1f57bd) |
| ZKRangeVerifier | `0xd1aDBC1af83aA4c5d37a77E081eaD466928D0d8a` | [View](https://sepolia.etherscan.io/address/0xd1adbc1af83aa4c5d37a77e081ead466928d0d8a) |
| ZKAuctionStrategy | `0xFf911FFf671A1FAF3BfdE0b3e08Ccba96f20b969` | [View](https://sepolia.etherscan.io/address/0xff911fff671a1faf3bfde0b3e08ccba96f20b969) |

### Gas Cost Snapshot

| Contract | Gas Used | Cost @ 1 gwei |
|----------|----------|---------------|
| Halo2Verifier | 450,000 | 0.00045 ETH |
| ZKRangeVerifier | 234,000 | 0.00023 ETH |
| ZKAuctionStrategy | 406,000 | 0.00041 ETH |
| **Total Deployment** | ~1,090,000 | ~0.0011 ETH |

### Runtime Gas Costs

| Operation | Gas |
|-----------|-----|
| `verifyProof()` | ~20,500 |
| `scoreBid()` | ~25,700 |

---

## Previous Deployments

### Sepolia v1 (Stub Verifiers)

> **Deprecated** - These contracts used stub verification logic.

| Contract | Address |
|----------|---------|
| Halo2Verifier | `0x70631dbd1F9A16c6C9bC943e4f5A321400306f79` |
| ZKRangeVerifier | `0x0939c0466EA30DF74BbD28C8f4c458c784F7Ce04` |
| ZKAuctionStrategy | `0x071881B872ED0729b03FAfd78dBCD11c52Ae5aFA` |

---

## Mainnet

> **Not yet deployed.** Mainnet deployment deferred pending:
> - Formal circuit audit
> - Extended gas analysis under production load
