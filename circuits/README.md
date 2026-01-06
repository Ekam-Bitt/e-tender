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

## Production Notes

> ⚠️ **Important**: The on-chain `Halo2Verifier.sol` contains placeholder verification logic. For production:
>
> 1. Run the full Halo2 setup ceremony
> 2. Use `snark-verifier-sdk` to generate the actual verification code
> 3. Replace the placeholder `_verifyProof()` function with generated pairing checks

## License

MIT
