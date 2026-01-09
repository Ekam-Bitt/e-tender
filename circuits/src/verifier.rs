//! Production EVM Verifier Generation
//!
//! Uses snark-verifier-sdk to generate real Solidity verifiers
//! with actual cryptographic pairing verification.

use std::path::Path;
use halo2_base::utils::fs::gen_srs;
use halo2_base::halo2_proofs::{
    halo2curves::bn256::{Bn256, Fr, G1Affine},
    plonk::ProvingKey,
    poly::{kzg::commitment::ParamsKZG, commitment::Params},
};
use snark_verifier_sdk::{
    gen_pk,
    halo2::gen_snark_shplonk,
    evm::gen_evm_verifier_shplonk,
    CircuitExt, Snark,
};

use crate::range_circuit::RangeProofCircuit;

/// Generate KZG trusted setup parameters
pub fn generate_params(k: u32) -> ParamsKZG<Bn256> {
    gen_srs(k)
}

/// Generate proving key for range proof circuit
pub fn generate_proving_key(
    params: &ParamsKZG<Bn256>,
    circuit: &RangeProofCircuit,
) -> ProvingKey<G1Affine> {
    gen_pk(params, circuit, None)
}

/// Generate SNARK proof for range proof
pub fn generate_snark(
    params: &ParamsKZG<Bn256>,
    pk: &ProvingKey<G1Affine>,
    circuit: RangeProofCircuit,
) -> Snark {
    gen_snark_shplonk(params, pk, circuit, None::<&str>)
}

/// Generate Solidity verifier contract
/// 
/// Returns the deployment bytecode for the verifier contract
pub fn generate_evm_verifier(
    params: &ParamsKZG<Bn256>,
    pk: &ProvingKey<G1Affine>,
    output_path: Option<&Path>,
) -> Vec<u8> {
    let vk = pk.get_vk();
    let num_instance = vec![3]; // min, max, value
    
    gen_evm_verifier_shplonk::<RangeProofCircuit>(
        params,
        vk,
        num_instance,
        output_path,
    )
}

/// Generate EVM-compatible proof
#[cfg(feature = "evm_proof")]
pub fn generate_evm_proof(
    params: &ParamsKZG<Bn256>,
    pk: &ProvingKey<G1Affine>,
    circuit: RangeProofCircuit,
) -> Vec<u8> {
    use snark_verifier_sdk::evm::gen_evm_proof_shplonk;
    
    let instances = circuit.instances();
    gen_evm_proof_shplonk(params, pk, circuit, instances)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_params_generation() {
        let params = generate_params(8);
        assert!(params.k() == 8);
    }

    #[test]
    fn test_proving_key_generation() {
        let params = generate_params(8);
        let circuit = RangeProofCircuit::new(10, 100, 50);
        let pk = generate_proving_key(&params, &circuit);
        assert!(pk.get_vk().cs().num_instance_columns() > 0);
    }
}
