# Halo2 Range Proof Circuit

Zero-knowledge range proof circuit for the e-tendering protocol, proving that a bid value falls within `[min, max]` without revealing additional information.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Off-chain (Rust)                            │
├─────────────────────────────────────────────────────────────────┤
│  range-proof-cli prove --min 10 --max 100 --value 50            │
│                         │                                       │
│                         ▼                                       │
│              Generates: proof.bin (Halo2 KZG proof)             │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     On-chain (Solidity)                         │
├─────────────────────────────────────────────────────────────────┤
│  ZKAuctionStrategy.scoreBid(amount, proof)                      │
│                         │                                       │
│                         ▼                                       │
│  ZKRangeVerifier.verifyProof(proof, [min, max, value])          │
│                         │                                       │
│                         ▼                                       │
│  Halo2Verifier.verify(proof, instances) → true/false            │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Rust 1.70+ (install via `rustup`)
- Cargo

## Usage

### 1. Build the CLI

```bash
cd circuits
cargo build --release
```

### 2. Generate Proving Keys (One-time setup)

```bash
./target/release/range-proof-cli generate-keys --output ./keys
```

### 3. Create a Proof

```bash
# Prove that 50 is in range [10, 100]
./target/release/range-proof-cli prove \
    --min 10 \
    --max 100 \
    --value 50 \
    --output proof.bin
```

### 4. Verify Locally

```bash
./target/release/range-proof-cli verify \
    --proof proof.bin \
    --min 10 \
    --max 100 \
    --value 50
```

### 5. Generate Hex for Solidity Tests

```bash
./target/release/range-proof-cli prove-hex --min 10 --max 100 --value 50
# Output: 0x...
```

### 6. Generate Solidity Verifier (Advanced)

```bash
./target/release/range-proof-cli gen-solidity --output Halo2Verifier.sol --k 8
```

> **Note**: Use `--help` to see all available CLI subcommands and options.

## Circuit Design

### Public Inputs (Instances)

| Index | Name | Description |
|-------|------|-------------|
| 0 | `min_bid` | Minimum allowed bid |
| 1 | `max_bid` | Maximum allowed bid |
| 2 | `bid_value` | The bid amount being proven |

### Constraints

The circuit enforces:

```
diff_min = bid_value - min_bid  ≥ 0
diff_max = max_bid - bid_value  ≥ 0
```

This proves: `min_bid ≤ bid_value ≤ max_bid`

## Testing

```bash
cargo test
```

## Trust Assumptions & Security Model

### Cryptographic Assumptions

| Assumption | Basis | Impact if Broken |
|------------|-------|------------------|
| Discrete Log hardness | BN254 curve | Proofs could be forged |
| Random Oracle Model | Fiat-Shamir heuristic | Soundness compromised |
| Trusted Setup (KZG) | Powers of tau ceremony | Universal forgery |

### What This Circuit Guarantees

✅ **Soundness**: A verifier accepts only if `min ≤ value ≤ max`  
✅ **Zero-Knowledge**: The exact `value` is not revealed  
✅ **Non-Malleability**: Proofs cannot be modified to verify different inputs  

### What This Circuit Does NOT Guarantee

❌ **Value Authenticity**: The circuit proves knowledge of a valid value, not that it matches a real bid  
❌ **Replay Protection**: Same proof could be reused if not tied to a nonce/address  
❌ **DoS Resistance**: Verification is ~14k gas but could be spammed  

### Production Deployment Status

✅ **Deployed on Sepolia**: Real BN254 pairing verification implemented  
✅ **Trusted Setup**: Using publicly audited Powers of Tau (multi-party SRS)  
✅ **Verified on Etherscan**: Source code verified for transparency  

**Pending for Mainnet:**
1. Formal circuit audit by ZK specialists
2. Extended gas analysis under production load
3. Proof binding to bidder address/nonce for replay protection

### Gas Costs (Production)

| Operation | Gas | Notes |
|-----------|-----|-------|
| `verifyProof()` | ~20,500 | Real BN254 pairing via precompile |
| `scoreBid()` | ~25,700 | Includes strategy overhead |

## Current Deployment (Sepolia)

| Contract | Address | Status |
|----------|---------|--------|
| Halo2Verifier | `0x03Fa77170645Bd424D5e273a921D8b76CA1F57BD` | ✅ Verified |
| ZKRangeVerifier | `0xd1aDBC1af83aA4c5d37a77E081eaD466928D0d8a` | ✅ Verified |
| ZKAuctionStrategy | `0xFf911FFf671A1FAF3BfdE0b3e08Ccba96f20b969` | ✅ Verified |

**Implementation**: Real BN254 pairing via ecPairing precompile (0x08)
**Gas**: ~20.5k per verification

> **Note**: Mainnet deployment deferred pending formal circuit audit.

## License

MIT
