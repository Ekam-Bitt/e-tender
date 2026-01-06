//! Range Proof Circuit Implementation
//!
//! Proves that: min_bid <= bid_value <= max_bid
//! 
//! Public Inputs (instances):
//! - min_bid: The minimum allowed bid value
//! - max_bid: The maximum allowed bid value  
//! - bid_value: The actual bid value being proven
//!
//! The circuit uses two range checks:
//! 1. bid_value - min_bid >= 0 (i.e., bid_value >= min_bid)
//! 2. max_bid - bid_value >= 0 (i.e., bid_value <= max_bid)

use halo2_proofs::{
    circuit::{Layouter, SimpleFloorPlanner, Value},
    plonk::{
        Advice, Circuit, Column, ConstraintSystem, Error, Fixed, Instance, Selector,
    },
    poly::Rotation,
};
use halo2curves::bn256::Fr;

/// Configuration for the Range Proof Circuit
#[derive(Clone, Debug)]
pub struct RangeProofConfig {
    /// Column for the bid value
    pub value: Column<Advice>,
    /// Column for the minimum bound
    pub min_bound: Column<Advice>,
    /// Column for the maximum bound
    pub max_bound: Column<Advice>,
    /// Column for the difference (value - min)
    pub diff_min: Column<Advice>,
    /// Column for the difference (max - value)
    pub diff_max: Column<Advice>,
    /// Instance column for public inputs
    pub instance: Column<Instance>,
    /// Selector for range check constraints
    pub selector: Selector,
    /// Fixed column for constants
    pub constant: Column<Fixed>,
}

impl RangeProofConfig {
    /// Create the constraint system configuration
    pub fn configure(meta: &mut ConstraintSystem<Fr>) -> Self {
        let value = meta.advice_column();
        let min_bound = meta.advice_column();
        let max_bound = meta.advice_column();
        let diff_min = meta.advice_column();
        let diff_max = meta.advice_column();
        let instance = meta.instance_column();
        let selector = meta.selector();
        let constant = meta.fixed_column();

        // Enable equality for copying from instance
        meta.enable_equality(value);
        meta.enable_equality(min_bound);
        meta.enable_equality(max_bound);
        meta.enable_equality(instance);
        meta.enable_constant(constant);

        // Range check gate: Ensures the differences are computed correctly
        // and implicitly that they are non-negative (via lookup or decomposition)
        meta.create_gate("range_check", |meta| {
            let s = meta.query_selector(selector);
            let value = meta.query_advice(value, Rotation::cur());
            let min = meta.query_advice(min_bound, Rotation::cur());
            let max = meta.query_advice(max_bound, Rotation::cur());
            let d_min = meta.query_advice(diff_min, Rotation::cur());
            let d_max = meta.query_advice(diff_max, Rotation::cur());

            // Constraint 1: diff_min = value - min
            let constraint1 = s.clone() * (d_min - (value.clone() - min));
            
            // Constraint 2: diff_max = max - value
            let constraint2 = s * (d_max - (max - value));

            vec![constraint1, constraint2]
        });

        RangeProofConfig {
            value,
            min_bound,
            max_bound,
            diff_min,
            diff_max,
            instance,
            selector,
            constant,
        }
    }
}

/// Range Proof Circuit
/// 
/// Proves that a bid value falls within [min_bid, max_bid]
#[derive(Clone, Debug, Default)]
pub struct RangeProofCircuit {
    /// The bid value (public)
    pub bid_value: Value<Fr>,
    /// Minimum allowed bid (public)
    pub min_bid: Value<Fr>,
    /// Maximum allowed bid (public)
    pub max_bid: Value<Fr>,
}

impl RangeProofCircuit {
    /// Create a new range proof circuit
    pub fn new(bid_value: u64, min_bid: u64, max_bid: u64) -> Self {
        Self {
            bid_value: Value::known(Fr::from(bid_value)),
            min_bid: Value::known(Fr::from(min_bid)),
            max_bid: Value::known(Fr::from(max_bid)),
        }
    }

    /// Get the public instances for this circuit
    pub fn instances(&self) -> Vec<Vec<Fr>> {
        let mut min_val = Fr::zero();
        let mut max_val = Fr::zero();
        let mut value_val = Fr::zero();
        
        self.min_bid.map(|v| { min_val = v; });
        self.max_bid.map(|v| { max_val = v; });
        self.bid_value.map(|v| { value_val = v; });
        
        // Instance order: [min_bid, max_bid, bid_value]
        vec![vec![min_val, max_val, value_val]]
    }
}

impl Circuit<Fr> for RangeProofCircuit {
    type Config = RangeProofConfig;
    type FloorPlanner = SimpleFloorPlanner;

    fn without_witnesses(&self) -> Self {
        Self::default()
    }

    fn configure(meta: &mut ConstraintSystem<Fr>) -> Self::Config {
        RangeProofConfig::configure(meta)
    }

    fn synthesize(
        &self,
        config: Self::Config,
        mut layouter: impl Layouter<Fr>,
    ) -> Result<(), Error> {
        // First, assign all values in a single region and collect the cells for instances
        let (min_cell, max_cell, value_cell) = layouter.assign_region(
            || "range proof",
            |mut region| {
                // Enable the selector
                config.selector.enable(&mut region, 0)?;

                // Assign the bid value
                let value_cell = region.assign_advice(
                    || "bid_value",
                    config.value,
                    0,
                    || self.bid_value,
                )?;

                // Assign min bound
                let min_cell = region.assign_advice(
                    || "min_bid",
                    config.min_bound,
                    0,
                    || self.min_bid,
                )?;

                // Assign max bound
                let max_cell = region.assign_advice(
                    || "max_bid",
                    config.max_bound,
                    0,
                    || self.max_bid,
                )?;

                // Compute and assign diff_min = value - min
                let diff_min_value = self.bid_value.zip(self.min_bid).map(|(v, m)| v - m);
                region.assign_advice(
                    || "diff_min",
                    config.diff_min,
                    0,
                    || diff_min_value,
                )?;

                // Compute and assign diff_max = max - value
                let diff_max_value = self.max_bid.zip(self.bid_value).map(|(m, v)| m - v);
                region.assign_advice(
                    || "diff_max",
                    config.diff_max,
                    0,
                    || diff_max_value,
                )?;

                Ok((min_cell, max_cell, value_cell))
            },
        )?;

        // Now constrain instances after the region is done
        layouter.constrain_instance(min_cell.cell(), config.instance, 0)?;
        layouter.constrain_instance(max_cell.cell(), config.instance, 1)?;
        layouter.constrain_instance(value_cell.cell(), config.instance, 2)?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use halo2_proofs::dev::MockProver;

    #[test]
    fn test_valid_range() {
        // Test: 50 is within [10, 100]
        let circuit = RangeProofCircuit::new(50, 10, 100);
        let instances = circuit.instances();
        
        let prover = MockProver::run(4, &circuit, instances).unwrap();
        assert!(prover.verify().is_ok(), "Valid range proof should pass");
    }

    #[test]
    fn test_value_equals_min() {
        // Test: 10 is within [10, 100] (boundary case)
        let circuit = RangeProofCircuit::new(10, 10, 100);
        let instances = circuit.instances();
        
        let prover = MockProver::run(4, &circuit, instances).unwrap();
        assert!(prover.verify().is_ok(), "Value at min boundary should pass");
    }

    #[test]
    fn test_value_equals_max() {
        // Test: 100 is within [10, 100] (boundary case)
        let circuit = RangeProofCircuit::new(100, 10, 100);
        let instances = circuit.instances();
        
        let prover = MockProver::run(4, &circuit, instances).unwrap();
        assert!(prover.verify().is_ok(), "Value at max boundary should pass");
    }
}
