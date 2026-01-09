# UI Integration Guide

## Overview

The e-Tendering protocol supports different "Identity Modes" for tenders. The UI must clearly distinguish between **Verified** (Secure) and **Public** (Unverified/Legacy) tenders to protect users.

---

## 🔒 distinguishing Tender Types

### 1. Check Identity Mode

The UI should call `Tender.getIdentityType()` to determine the verification level.

| Return Value (string) | Display Label | Badge Color | User Warning |
|-----------------------|---------------|-------------|--------------|
| `"ADDRESS"` | **Public / Unverified** | 🔴 Red | "⚠️ Warning: This tender has NO identity verification. Bids may be sybiled." |
| `"ZK_NULLIFIER"` | **Verified (Anonymous)** | 🟢 Green | "✅ Verified: Sybil-resistant via ZK Proofs." |
| `"ISSUER_SIGNATURE"` | **Verified (Permissioned)** | 🔵 Blue | "✅ Verified: Restricted to authorized entities." |

### 2. Implementation Logic

```javascript
const typeBytes = await tenderContract.getIdentityType();
const typeString = web3.utils.hexToUtf8(typeBytes);

if (typeString === "ADDRESS") {
    showUnverifiedWarning();
} else {
    showVerifiedBadge();
}
```

---

## 📡 Monitoring & Events

### Legacy Mode Usage

To track usage of the "Public" (Legacy) mode, monitor the `IdentityVerificationBypassed` event.

**Event Signature:**
`event IdentityVerificationBypassed()`

**When Emitted:**
- Emitted during `submitBid` if the Identity Mode is `NONE`.
- Indicates a bid was accepted without cryptographic identity verification.

**Monitoring Rule:**
- **Alert:** If `IdentityVerificationBypassed` frequency > Threshold.
- **Action:** Investigating why users aren't using ZK/Signature modes.

---

## 📝 Compliance Logging

All sensitive actions emit `ComplianceLog` events. Monitors should index these to reconstruct the audit trail.

- `REG_TENDER_CREATED` (ID: 0)
- `REG_BID_SUBMITTED` (ID: 1)
- `REG_BID_REVEALED` (ID: 2)
- `REG_DISPUTE_OPENED` (ID: 4)
