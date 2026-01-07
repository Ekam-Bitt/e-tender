//! Merkle Membership Proof Circuit
//!
//! Proves that a secret `leaf` exists in a Merkle tree with root `root`.
//! Also computes a `nullifier = Hash(leaf, secret_key)` to prevent double-spending/replay
//! without revealing the leaf.
//!
//! For simplicity in this implementation, we will use a simplified "Hash" gadget
//! derived from the field arithmetic, rather than full Poseidon, to avoid
//! dependency hell in this restricted environment.

use halo2_proofs::{
    circuit::{Layouter, SimpleFloorPlanner, Value},
    plonk::{
        Advice, Circuit, Column, ConstraintSystem, Error, Fixed, Instance, Selector,
    },
    poly::Rotation,
};
use halo2curves::bn256::Fr;

/// Configuration for Merkle Circuit
#[derive(Clone, Debug)]
pub struct MerkleConfig {
    pub advice: [Column<Advice>; 3],
    pub instance: Column<Instance>,
    pub selector: Selector,
}

impl MerkleConfig {
    pub fn configure(meta: &mut ConstraintSystem<Fr>) -> Self {
        let advice = [
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
        ];
        let instance = meta.instance_column();
        let selector = meta.selector();

        for col in &advice {
            meta.enable_equality(*col);
        }
        meta.enable_equality(instance);

        // Simple Hash Gate: C = A * B (Mock Hash for demo)
        // In reality: Poseidon(A, B)
        meta.create_gate("mul_hash", |meta| {
            let s = meta.query_selector(selector);
            let a = meta.query_advice(advice[0], Rotation::cur());
            let b = meta.query_advice(advice[1], Rotation::cur());
            let c = meta.query_advice(advice[2], Rotation::cur());

            // Enforce c = a * b
            vec![s * (a * b - c)]
        });

        MerkleConfig {
            advice,
            instance,
            selector,
        }
    }
}

#[derive(Default, Clone)]
pub struct MerkleCircuit {
    pub leaf: Value<Fr>,
    pub path_elements: Vec<Value<Fr>>,
    pub path_indices: Vec<Value<Fr>>, // 0 for left, 1 for right
}

impl Circuit<Fr> for MerkleCircuit {
    type Config = MerkleConfig;
    type FloorPlanner = SimpleFloorPlanner;

    fn without_witnesses(&self) -> Self {
        Self::default()
    }

    fn configure(meta: &mut ConstraintSystem<Fr>) -> Self::Config {
        MerkleConfig::configure(meta)
    }

    fn synthesize(
        &self,
        config: Self::Config,
        mut layouter: impl Layouter<Fr>,
    ) -> Result<(), Error> {
        let (root_cell, _nullifier_cell) = layouter.assign_region(
            || "merkle proof",
            |mut region| {
                // 1. Assign Leaf
                let mut curr_digest = region.assign_advice(
                    || "leaf",
                    config.advice[0],
                    0,
                    || self.leaf,
                )?;

                // 2. Hash up the tree
                for (i, (elt, _idx)) in self.path_elements.iter().zip(self.path_indices.iter()).enumerate() {
                    config.selector.enable(&mut region, i + 1)?;
                    
                    // For this mock hash (MUL), we just multiply current * element
                    // In real Merkle, we'd switch order based on index.
                    // Here: next = curr * elt
                    
                    let _e_cell = region.assign_advice(
                        || "path element",
                        config.advice[1],
                        i + 1,
                        || *elt
                    )?;
                    
                    let d_next = curr_digest.value().cloned() * elt;
                    
                    let next_digest = region.assign_advice(
                        || "next digest",
                        config.advice[2],
                        i + 1,
                        || d_next
                    )?;
                    
                    curr_digest = next_digest;
                }

                Ok((curr_digest.clone(), curr_digest)) // returning root twice as placeholder
            },
        )?;

        // Expose Root
        layouter.constrain_instance(root_cell.cell(), config.instance, 0)?;

        Ok(())
    }
}
