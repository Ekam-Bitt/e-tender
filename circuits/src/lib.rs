//! Halo2 Circuits for e-Tendering Protocol
//!
//! Production-grade ZK circuits using Axiom's halo2-lib and snark-verifier-sdk.

// Re-export halo2 types
pub use halo2_base::halo2_proofs;
pub use snark_verifier_sdk;

pub mod range_circuit;
pub mod nullifier_circuit;
pub mod verifier;

pub use range_circuit::RangeProofCircuit;
pub use nullifier_circuit::build_nullifier_circuit;
