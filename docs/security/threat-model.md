# Threat Model

## 1. System Overview
This e-tendering system leverages a blockchain (Ethereum-compatible) to provide transparency, immutability, and fairness in the procurement process. It utilizes a **Commit-Reveal** scheme to ensure bid secrecy during the bidding phase and smart contracts to enforce process rules.

## 2. Actors and Roles

| Actor | Description | Capabilities |
|-------|-------------|--------------|
| **Authority** | The entity issuing the tender (e.g., Govt Dept, Company). | Deploy TenderFactory, Create Tenders, Set Requirements, Finalize Awards (based on SC logic). |
| **Bidder** | Any entity submitting a proposal. | Deposit Bid Bond, Submit Hashed Bid (Commit), Reveal Bid, Withdraw Bond (if not winner/slashed). |
| **Auditor** | Independent verifier (optional/external). | Verify on-chain events, Audit smart contract code, Dispute resolution (if Governance layer exists). |
| **Observer** | Public or non-participating entity. | Read state, Verify proofs, Monitor events. |

## 3. Adversaries and Threat capabilities

### 3.1 Malicious Bidder
- **Goal**: Win unfairly, disrupt the process, or learn others' bids.
- **Capabilities**:
  - Can generate multiple addresses (Sybil).
  - Can submit invalid or spam bids.
  - Can refuse to reveal the bid after commitment.
  - Can front-run transactions (if not mitigated).

### 3.2 Colluding Authority
- **Goal**: Favor a specific bidder, leak bid information, or censor valid bids.
- **Capabilities**:
  - Cannot undetectably alter smart contract logic after deployment.
  - *Could* try to censor transactions (unlikely if L1 is decentralized, but could ignore off-chain discovery).
  - *Could* tailor tender requirements (Project Specs) to fit a specific crony (out of scope for SC, but auditable).

### 3.3 Network-Level Attacker
- **Goal**: DoS the system, delay bids until deadline passes.
- **Capabilities**:
  - Front-running / MEV bot (Generic).
  - Network congestion attacks.

## 4. Trust Assumptions
- **Trust-Minimization**: We do **not** trust the Authority to keep bids secret (handled by Commit-Reveal).
- **L1 Security**: We assume the underlying blockchain consensus is honest and liveness is maintained.
- **Client Security**: We assume users protect their private keys.
- **Rationality**: We assume actors are economically rational (will not burn money for no gain).

## 5. Assets
- **Confidentiality**: Bid amounts and details must remain secret until the Reveal phase.
- **Integrity**: Tender documents and submitted bids cannot be modified.
- **Availability**: The system must accept bids during the Open phase.
- **Fairness**: All valid bids submitted on time must be evaluated by the same rules.

## 6. Attack Vectors and Mitigations

| Attack Vector | Description | Risk Level | Mitigation Strategy |
|---------------|-------------|------------|---------------------|
| **Bid Secrecy Leak** | Authority or Competitors seeing bids before deadline to undercut. | High | **Commit-Reveal Scheme**: Bids are hashed (`keccak256(amount, salt)`). Only hash is stored on-chain. |
| **Bid Rigging / Censorship** | Authority modifying bids or deleting them. | High | **Immutability**: Once committed to the blockchain, the hash cannot be changed. Censorship is difficult on public chains. |
| **Last-Minute Bidding (Sniping)** | Bidders waiting for the last block to submit. | Medium | **Hard Deadlines**: Smart contract enforces block-time/number deadlines. Commit phase ends strictly before Reveal phase. |
| **Bid Suppression** | Preventing a competitor from bidding via DoS. | Medium | **Public Chain**: High gas fees may occur, but total blocking is hard. **Time Windows**: Sufficiently long bidding periods. |
| **Sybil Attack** | Flooding the tender with fake bids. | Low/Med | **Bid Bond / Deposit**: Bidders must lock ETH/Tokens to bid. Forfeited if they misbehave (e.g., don't reveal). |
| **Non-Reveal Griefing** | Winner refuses to reveal or verify, stalling process. | Medium | **Incentives**: If a user commits but does not reveal, they lose their Bid Bond (deposit). |
| **Front-Running (MEV)** | Observer seeing a tx in mempool and acting on it. | Low | Commit-Reveal makes the content opaque. Ordering matters less in the commit phase if secrecy is held. |

## 7. Accepted Risks
- **Collusion off-chain**: Bidders talking to each other off-chain cannot be prevented by code.
- **Authority "Spec rigging"**: Authority defining "Requirements: Must be Red Company Inc" is a governance issue, though key-value checks can be automated.
- **Key Compromise**: Users losing keys lose access/funds.
