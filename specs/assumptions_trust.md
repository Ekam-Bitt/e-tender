# Assumptions and Trust Model

## 1. Explicit Assumptions

### 1.1 Technical Assumptions
*   **Synchronous Clocks**: We rely on `block.timestamp` for deadline enforcement. While miners can manipulate this predominantly (approx 15-900s), for the scale of tendering (days/weeks), this variance is negligible.
*   **Crypto Hardness**: We assume Keccak256 is collision-resistant and pre-image resistant.
*   **Off-chain Storage**: We assume Tender Metadata (PDFs, large specs) stored on IPFS/Arweave is available. The Smart Contract only stores the Content ID (CID/Hash). If IPFS goes down, the contract state remains valid but human readability is impaired.

### 1.2 Economic Assumptions
*   **Rational Bidders**: Bidders want to win or retrieve their deposit. They will not grief the system if it costs them their Bid Bond.
*   **Sufficient Bond**: The `Bid Bond` amount is significant enough to deter spam but low enough to allow participation.

### 1.3 Procedural Assumptions
*   **Dispute Resolution**: Code is law for the *process* (timings, selection math), but legal disputes (e.g., "The delivered bridge collapsed") happen off-chain. This system guarantees the *procurement* integrity, not the *execution* of the job.

## 2. Trust Model (Who do we trust?)

| Entity | Trusted? | With What? | Justification |
| :--- | :--- | :--- | :--- |
| **Blockchain (Ethereum)** | YES | Consensus, Ordering, State Storage | Decentralized infrastructure assumption. |
| **Smart Contract Code** | YES | Logic execution | Verified code, immutable (orphaned from admin control except for specific emergency hatches if designed). |
| **Tender Authority** | PARTIAL | Defining Specs, Emergency Cancel | They initiate the tender. We do NOT trust them to keep bids secret (hence Commit-Reveal). |
| **Bidders** | NO | Honest behavior | Mechanism design (bonds) forces honest behavior or punishes deviation. |
| **Oracles** | N/A | (Ideally None) | System is designed to be self-contained to avoid oracle manipulation risks. |

## 3. What we DO NOT Trust (Adversarial coverage)
*   **Secret-keeping**: We do not trust any single server to keep bids encrypted. Bids are secrets held by bidders until reveal.
*   **Censorship**: We do not trust the Authority to include all bids. The blockchain mempool ensures open access.
*   **Modification**: We do not trust a database admin. The ledger is immutable.
