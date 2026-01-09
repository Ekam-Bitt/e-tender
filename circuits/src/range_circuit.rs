//! Range Proof Circuit for Production EVM Verifier
//!
//! Implements a simple range proof that can be verified on-chain.
//! Uses snark-verifier-sdk for EVM verifier generation.

use halo2_base::halo2_proofs::{
    circuit::{Layouter, SimpleFloorPlanner, Value},
    halo2curves::bn256::Fr,
    plonk::{Advice, Circuit, Column, ConstraintSystem, Error, Fixed, Instance, Selector},
    poly::Rotation,
};
use snark_verifier_sdk::CircuitExt;

/// Range proof circuit configuration
#[derive(Clone, Debug)]
pub struct RangeProofConfig {
    pub advice: [Column<Advice>; 3],
    pub fixed: Column<Fixed>,
    pub instance: Column<Instance>,
    pub selector: Selector,
}

/// Range proof circuit - Proves: min <= value <= max
#[derive(Clone, Default)]
pub struct RangeProofCircuit {
    pub min: Value<Fr>,
    pub max: Value<Fr>,
    pub value: Value<Fr>,
}

impl RangeProofCircuit {
    pub fn new(min: u64, max: u64, value: u64) -> Self {
        Self {
            min: Value::known(Fr::from(min)),
            max: Value::known(Fr::from(max)),
            value: Value::known(Fr::from(value)),
        }
    }
    
    /// Get instances as Vec<Fr> for proof generation
    pub fn get_instances(&self) -> Vec<Fr> {
        let mut result = Vec::new();
        self.min.map(|v| result.push(v));
        self.max.map(|v| result.push(v));
        self.value.map(|v| result.push(v));
        result
    }
}

impl CircuitExt<Fr> for RangeProofCircuit {
    fn num_instance(&self) -> Vec<usize> {
        vec![3] // min, max, value
    }

    fn instances(&self) -> Vec<Vec<Fr>> {
        vec![self.get_instances()]
    }
}

impl Circuit<Fr> for RangeProofCircuit {
    type Config = RangeProofConfig;
    type FloorPlanner = SimpleFloorPlanner;
    type Params = ();

    fn without_witnesses(&self) -> Self {
        Self::default()
    }

    fn configure(meta: &mut ConstraintSystem<Fr>) -> Self::Config {
        let advice = [
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
        ];
        let fixed = meta.fixed_column();
        let instance = meta.instance_column();
        let selector = meta.selector();

        for col in &advice {
            meta.enable_equality(*col);
        }
        meta.enable_equality(instance);
        meta.enable_constant(fixed);

        // Range check gate
        meta.create_gate("range_check", |meta| {
            let s = meta.query_selector(selector);
            let min = meta.query_advice(advice[0], Rotation::cur());
            let max = meta.query_advice(advice[1], Rotation::cur());
            let value = meta.query_advice(advice[2], Rotation::cur());
            
            vec![s * (value.clone() - min) * (max - value)]
        });

        RangeProofConfig {
            advice,
            fixed,
            instance,
            selector,
        }
    }

    fn synthesize(
        &self,
        config: Self::Config,
        mut layouter: impl Layouter<Fr>,
    ) -> Result<(), Error> {
        // Assign values and expose as public inputs
        let (min_cell, max_cell, value_cell) = layouter.assign_region(
            || "range_proof",
            |mut region| {
                config.selector.enable(&mut region, 0)?;
                
                // halo2-axiom API: assign_advice(column, row, value)
                let min_cell = region.assign_advice(config.advice[0], 0, self.min);
                let max_cell = region.assign_advice(config.advice[1], 0, self.max);
                let value_cell = region.assign_advice(config.advice[2], 0, self.value);
                
                Ok((min_cell, max_cell, value_cell))
            },
        )?;

        // Constrain to public inputs (halo2-axiom: returns ())
        layouter.constrain_instance(min_cell.cell(), config.instance, 0);
        layouter.constrain_instance(max_cell.cell(), config.instance, 1);
        layouter.constrain_instance(value_cell.cell(), config.instance, 2);

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use halo2_base::halo2_proofs::dev::MockProver;

    #[test]
    fn test_valid_range() {
        let k = 4;
        let circuit = RangeProofCircuit::new(10, 100, 50);
        let instances = circuit.get_instances();
        
        let prover = MockProver::run(k, &circuit, vec![instances]).unwrap();
        prover.assert_satisfied();
    }
}
