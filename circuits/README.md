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
./target/release/range-proof-cli gen-solidity --output Halo2Verifier.sol
```

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

### Production Deployment Requirements

> ⚠️ **Important**: The on-chain `Halo2Verifier.sol` contains placeholder verification logic.

For production readiness:

1. **Trusted Setup**: Run full Halo2 KZG ceremony (or use existing universal SRS)
2. **Verifier Generation**: Use `snark-verifier-sdk` to generate actual pairing checks
3. **Audit**: Have the circuit and verifier audited by ZK specialists
4. **Binding**: Ensure proofs are bound to bidder address/nonce to prevent replay

### Gas Costs

| Operation | Gas | Notes |
|-----------|-----|-------|
| `verifyProof()` | ~14,000 | Acceptable for high-value tenders |
| `scoreBid()` | ~19,000 | Includes strategy overhead |
| Full pairing verification | ~300,000 (est.) | Production with real pairings |

## Development vs Production

```
┌─────────────────────────────────────────────────────────────────┐
│  CURRENT STATE: Development/Testing                             │
│  - MockProver for local verification                            │
│  - Placeholder Solidity verifier                                │
│  - Semantic range checks only (no cryptographic verification)   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PRODUCTION STATE: Full ZK Security                             │
│  - KZG proofs with trusted setup                                │
│  - Real pairing verification in Solidity                        │
│  - Cryptographic binding of proofs to public inputs             │
└─────────────────────────────────────────────────────────────────┘
```

## License

MIT

