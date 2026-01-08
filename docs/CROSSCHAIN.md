# Cross-Chain CCIP Integration Guide

> **Status:** Live on Sepolia + Fuji Testnets  
> **Protocol:** Chainlink CCIP

---

## Overview

The e-tendering protocol supports **cross-chain bid submission** via Chainlink CCIP (Cross-Chain Interoperability Protocol). This allows bidders on one chain (e.g., Avalanche) to submit bids to tenders on another chain (e.g., Ethereum).

```
┌─────────────────┐                   ┌─────────────────┐
│   Fuji (AVAX)   │                   │  Sepolia (ETH)  │
│                 │                   │                 │
│  CCIPBidSender  │ ───── CCIP ────▸  │ CCIPBidReceiver │
│                 │                   │       │         │
└─────────────────┘                   │       ▼         │
                                      │    Tender.sol   │
                                      └─────────────────┘
```

---

## Deployed Contracts

| Chain | Contract | Address |
|-------|----------|---------|
| Sepolia | CCIPBidReceiver | [`0x645921f20f8ac70282333ad29476e23f820d4839`](https://sepolia.etherscan.io/address/0x645921f20f8ac70282333ad29476e23f820d4839) |
| Fuji | CCIPBidSender | [`0x2a0268581776f639f08878a3ae504e2b13deb7fc`](https://testnet.snowtrace.io/address/0x2a0268581776f639f08878a3ae504e2b13deb7fc) |

---

## How It Works

### 1. Sending a Cross-Chain Bid (Source Chain)

```solidity
// On Fuji: estimate fee and send bid
uint256 fee = sender.estimateFee(SEPOLIA_SELECTOR, tenderAddress, commitment);
sender.sendBid{value: fee}(SEPOLIA_SELECTOR, tenderAddress, commitment);
```

### 2. Receiving the Bid (Destination Chain)

The `CCIPBidReceiver` contract:
1. Receives the CCIP message
2. Validates source chain and sender permissions
3. Computes a cross-chain `bidderId`
4. Calls `Tender.submitCrossChainBid()`

### 3. Bidder ID Computation

Cross-chain bidder IDs are computed as:
```solidity
bytes32 bidderId = keccak256(
    abi.encodePacked("CROSSCHAIN_BIDDER", sourceChainSelector, originalSender)
);
```

This ensures uniqueness across chains while maintaining replay protection.

---

## Deployment Guide

### Prerequisites

```bash
# Set environment variables
export PRIVATE_KEY_ETH=<ethereum-private-key>
export PRIVATE_KEY_AVAX=<avalanche-private-key>
export SEPOLIA_RPC=https://ethereum-sepolia-rpc.publicnode.com
export FUJI_RPC=https://avalanche-fuji-c-chain-rpc.publicnode.com
```

### Deploy Receiver (Sepolia)

```bash
forge script script/DeployCCIP.s.sol:DeployCCIPReceiver \
  --rpc-url $SEPOLIA_RPC --broadcast
```

### Deploy Sender (Fuji)

```bash
forge script script/DeployCCIP.s.sol:DeployCCIPSender \
  --rpc-url $FUJI_RPC --broadcast
```

### Configure Permissions

```bash
# Allow Fuji sender on Sepolia receiver
cast send <RECEIVER_ADDRESS> \
  "allowSender(uint64,address,bool)" \
  14767482510784806043 <SENDER_ADDRESS> true \
  --rpc-url $SEPOLIA_RPC --private-key $PRIVATE_KEY_ETH
```

---

## CCIP Chain Selectors

| Chain | Selector |
|-------|----------|
| Sepolia | `16015286601757825753` |
| Fuji | `14767482510784806043` |

---

## Security Considerations

1. **Access Control**: Only authorized senders on allowed chains can submit bids
2. **Replay Protection**: Message IDs are tracked to prevent replay attacks
3. **Bond Forwarding**: The receiver must hold sufficient ETH to cover bid bonds

---

## Testing

```bash
# Run cross-chain tests
forge test --match-contract CrossChainAdapter -vv
```

All 13 cross-chain tests pass, including:
- Fee estimation
- Bid sending with refunds
- Message reception
- Replay protection
- Access control
