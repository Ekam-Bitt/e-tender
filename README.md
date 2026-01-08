<div align="center">

# Decentralized E-Tendering Protocol

**A trustless, on-chain procurement system for high-value tenders.**

[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)
[![CI](https://github.com/Ekam-Bitt/e-tender/actions/workflows/ci.yml/badge.svg)](https://github.com/Ekam-Bitt/e-tender/actions/workflows/ci.yml)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636.svg)](https://docs.soliditylang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Sepolia](https://img.shields.io/badge/Deployed-Sepolia-green.svg)](DEPLOYMENTS.md)

</div>

---

## 🎯 Overview

This protocol eliminates corporate espionage and corruption in high-value procurement by replacing trusted intermediaries with **cryptographic guarantees**. It enables **sealed-bid auctions** for $10M+ tenders entirely on-chain using:

- **Commit-Reveal Cryptography** — Bids remain secret until the reveal deadline
- **Zero-Knowledge Proofs** — Range validation without exposing bid amounts
- **Identity Verification** — Sybil-resistant, authorized-entity-only participation

> **Status:** Research-grade. Deployed to Sepolia testnet. Mainnet deployment pending formal audit.

---

## 🔌 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) (`forge`, `cast`, `anvil`)
- Rust toolchain (for ZK circuits)

### Installation

```bash
git clone --recurse-submodules https://github.com/your-org/e-tendering.git
cd e-tendering
forge install
```

### Build

```bash
forge build
```

### Test

```bash
# Unit tests
forge test --match-path "test/unit/*"

# Integration tests
forge test --match-path "test/integration/*"

# Invariant (fuzz) tests
forge test --match-path "test/invariants/*"

# All tests
forge test
```

---

## 🏗️ Architecture

The protocol operates as a **finite state machine** ensuring tenders progress irreversibly through valid states:

```
┌─────────┐     ┌──────┐     ┌────────┐     ┌────────────┐     ┌─────────┐     ┌──────────┐
│ CREATED │ ──▸ │ OPEN │ ──▸ │ REVEAL │ ──▸ │ EVALUATION │ ──▸ │ AWARDED │ ──▸ │ RESOLVED │
└─────────┘     └──────┘     └────────┘     └────────────┘     └─────────┘     └──────────┘
                   │              │                                  │
                   ▼              ▼                                  ▼
              Commitments    ZK Proofs +                        Disputes
              + Bonds        Reveals                            + Finalize
```

📄 **[Full State Machine Specification →](docs/specs/state-machine.md)**

---

## 📂 Project Structure

```
e-tendering/
├── src/
│   ├── core/              # Tender.sol, TenderFactory.sol
│   ├── crypto/            # Hash utilities, commitment schemes
│   ├── identity/          # Identity verifiers (address, ZK-based)
│   ├── strategies/        # Bid evaluation strategies (ZKAuctionStrategy)
│   ├── compliance/        # Regulatory logging module
│   └── interfaces/        # Contract interfaces
├── test/
│   ├── unit/              # Per-function tests
│   ├── integration/       # Cross-contract scenarios
│   └── invariants/        # Stateful fuzzing (solvency, monotonicity)
├── script/                # Deployment scripts
├── circuits/              # Halo2 ZK circuits (Rust)
└── docs/                  # Specifications & security docs
```

---

## 🔒 Security Model

### Attack Vectors Mitigated

| Attack | Mitigation |
|--------|------------|
| **Bid Leakage** | EIP-712 typed commitments hide bid contents |
| **Front-Running** | Salted hashes prevent MEV copy-cat attacks |
| **Retroactive Bidding** | Immutable `block.timestamp` enforces deadlines |
| **Sybil Attacks** | Identity verifiers ensure 1-entity-1-bid |
| **Invalid Bids** | ZK range proofs reject out-of-range values |

### Accepted Risks

| Risk | Assumption |
|------|------------|
| **L1 Downtime** | Underlying chain remains live |
| **Off-chain Collusion** | Protocol ensures *process* integrity, not *social* integrity |

📄 **[Full Threat Model →](docs/security/threat-model.md)**

---

## 🧪 Testing & Verification

We employ a comprehensive testing strategy beyond unit tests:

| Type | Tool | Coverage |
|------|------|----------|
| **Unit Tests** | Foundry | Per-function behavior |
| **Integration Tests** | Foundry | Cross-contract flows |
| **Stateless Fuzzing** | `forge fuzz` | Input edge cases |
| **Stateful Fuzzing** | `forge invariant` | System invariants |

### Key Invariants Proven

- **Solvency** — Contract ETH balance ≥ sum of active deposits
- **State Monotonicity** — Tender state never reverts to a previous state
- **Commitment Integrity** — Revealed values always match commitments

---

## 🔐 Zero-Knowledge Integration

The protocol uses **Halo2** (KZG polynomial commitments) for zero-knowledge range proofs:

| Property | Value |
|----------|-------|
| **Proof System** | Halo2 with KZG |
| **Setup** | Universal SRS (Powers of Tau) |
| **Proof Size** | ~192 bytes |
| **Verification Gas** | ~20,500 |

### ZK Contracts

| Contract | Description |
|----------|-------------|
| `Halo2Verifier.sol` | Core pairing-based verification |
| `ZKRangeVerifier.sol` | Public input formatting adapter |
| `ZKAuctionStrategy.sol` | Verification + bid scoring |

📄 **[Full ZK Integration Guide →](ZK_INTEGRATION.md)**

---

## 🌉 Cross-Chain Integration (CCIP)

The protocol supports **cross-chain bid submission** via Chainlink CCIP:

| Chain | Contract | Address |
|-------|----------|---------|
| Sepolia | CCIPBidReceiver | `0x645921f2...4839` |
| Fuji | CCIPBidSender | `0x2a026858...b7fc` |

**Features:**
- Submit bids from any CCIP-supported chain
- Automatic bidder ID computation for cross-chain identity
- Replay protection via message ID tracking
- Access-controlled sender authorization

📄 **[Full Cross-Chain Guide →](docs/CROSSCHAIN.md)**

---

## 🚀 Deployments

### Sepolia Testnet (Production)

| Contract | Address |
|----------|---------|
| Halo2Verifier | [`0x03Fa...57BD`](https://sepolia.etherscan.io/address/0x03fa77170645bd424d5e273a921d8b76ca1f57bd) |
| ZKRangeVerifier | [`0xd1aD...0d8a`](https://sepolia.etherscan.io/address/0xd1adbc1af83aa4c5d37a77e081ead466928d0d8a) |
| ZKAuctionStrategy | [`0xFf91...b969`](https://sepolia.etherscan.io/address/0xff911fff671a1faf3bfde0b3e08ccba96f20b969) |

📄 **[Full Deployment History →](DEPLOYMENTS.md)**

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [State Machine](docs/specs/state-machine.md) | Tender lifecycle states & transitions |
| [Threat Model](docs/security/threat-model.md) | Security analysis & attack vectors |
| [Trust Assumptions](docs/specs/assumptions_trust.md) | Protocol dependencies & guarantees |
| [ZK Integration](ZK_INTEGRATION.md) | Halo2 proof system details |
| [Deployments](DEPLOYMENTS.md) | Contract addresses & gas costs |

---

## ⚠️ Disclaimer

This is **research-grade software**. While rigorously tested with fuzzing and invariant proofs, it:

- Relies on the integrity of the Identity Oracle
- Assumes L1 consensus liveness
- Has not undergone formal security audit
- Is **not recommended for production use** without further verification

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Built with [Foundry](https://getfoundry.sh/) · Verified on [Ethereum Sepolia](https://sepolia.etherscan.io/)**

</div>
