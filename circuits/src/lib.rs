//! Halo2 Range Proof Circuit for e-Tendering Protocol
//!
//! This library provides a zero-knowledge range proof circuit that proves:
//! `min_bid <= bid_value <= max_bid` without revealing the actual values.

pub mod range_proof;
pub mod verifier_sol;

pub use range_proof::RangeProofCircuit;
