use halo2_base::{
    gates::{
        circuit::{builder::BaseCircuitBuilder, CircuitBuilderStage},
        GateInstructions,
    },
    halo2_proofs::{
        halo2curves::bn256::{Bn256, Fr, G1Affine},
        plonk::{ProvingKey},
        poly::kzg::{
            commitment::{KZGCommitmentScheme, ParamsKZG},
        },
    },
    poseidon::hasher::PoseidonSponge,
    utils::ScalarField,
};
use snark_verifier_sdk::{
    evm::gen_evm_verifier_shplonk,
    gen_pk,
};
use std::path::Path;

/// Function to build the nullifier circuit using BaseCircuitBuilder
/// Proves:
/// 1. commitment = Poseidon(secret, nonce)
/// 2. nullifier = Poseidon(secret, external_nullifier)
pub fn build_nullifier_circuit(
    stage: CircuitBuilderStage,
    commitment: Fr,
    nullifier: Fr,
    external_nullifier: Fr,
    secret: Fr,
    nonce: Fr,
    k: usize,
    lookup_bits: usize,
) -> BaseCircuitBuilder<Fr> {
    let mut builder = BaseCircuitBuilder::new(false);
    builder.set_k(k);
    builder.set_lookup_bits(lookup_bits);
    
    // Main context
    let ctx = builder.main(0);
    
    // Inputs (witness)
    let secret_assigned = ctx.load_witness(secret);
    let nonce_assigned = ctx.load_witness(nonce);
    let ext_nullifier_assigned = ctx.load_witness(external_nullifier);
    
    // Inputs (public)
    // We load them as witnesses first for comparison, then expose raw inputs as public instances
    let commitment_assigned = ctx.load_witness(commitment);
    let nullifier_assigned = ctx.load_witness(nullifier);
    
    // We need a GateChip to perform constraints/squeezing if needed by PoseidonSponge
    // halo2-base PoseidonSponge::squeeze takes (ctx, gate).
    let gate = halo2_base::gates::GateChip::default();
    
    // 1. Commitment = Poseidon(secret, nonce)
    // R_F=8, R_P=57 is standard for BN254 Poseidon (optimized)
    let mut sponge1 = PoseidonSponge::<Fr, 3, 2>::new::<8, 57, 0>(ctx);
    sponge1.update(&[secret_assigned, nonce_assigned]);
    let computed_commitment = sponge1.squeeze(ctx, &gate);
    
    // Constrain commitment
    ctx.constrain_equal(&computed_commitment, &commitment_assigned);
    
    // 2. Nullifier = Poseidon(secret, external_nullifier)
    let mut sponge2 = PoseidonSponge::<Fr, 3, 2>::new::<8, 57, 0>(ctx);
    sponge2.update(&[secret_assigned, ext_nullifier_assigned]);
    let computed_nullifier = sponge2.squeeze(ctx, &gate);
    
    // Constrain nullifier
    ctx.constrain_equal(&computed_nullifier, &nullifier_assigned);
    
    // Expose Public Instances
    // Order: [commitment, nullifier, external_nullifier]
    builder.set_instance_columns(1);
    builder.assigned_instances[0].push(commitment_assigned);
    builder.assigned_instances[0].push(nullifier_assigned);
    builder.assigned_instances[0].push(ext_nullifier_assigned);

    if stage != CircuitBuilderStage::Prover {
        // Mock or Keygen
        builder.calculate_params(Some(20));
    }

    builder
}


pub fn generate_nullifier_pk(
    params: &ParamsKZG<Bn256>,
    circuit: &BaseCircuitBuilder<Fr>,
) -> ProvingKey<G1Affine> {
    gen_pk(params, circuit, None)
}

pub fn generate_nullifier_evm_verifier(
    params: &ParamsKZG<Bn256>,
    pk: &ProvingKey<G1Affine>,
    path: Option<&Path>,
) -> Vec<u8> {
    let num_instance = vec![3]; // commitment, nullifier, ext_nullifier
    let vk = pk.get_vk(); // Extract VerifyingKey from ProvingKey
    
    if let Some(p) = path {
        gen_evm_verifier_shplonk::<BaseCircuitBuilder<Fr>>(
            params,
            vk,
            num_instance.clone(),
            Some(p),
        )
    } else {
        gen_evm_verifier_shplonk::<BaseCircuitBuilder<Fr>>(
            params,
            vk,
            num_instance,
            None,
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use halo2_base::halo2_proofs::dev::MockProver;
    use halo2_base::gates::circuit::CircuitBuilderStage;
    use snark_verifier_sdk::CircuitExt;


    #[test]
    fn test_nullifier_circuit() {
        let k = 10;
        let lookup_bits = 9;
        
        let secret = Fr::from(123);
        let nonce = Fr::from(456);
        let ext_nullifier = Fr::from(789);
        
        // Use the same circuit logic to compute valid hashes for testing
        // This effectively tests self-consistency
        
        let mut builder = BaseCircuitBuilder::new(false);
        builder.set_k(k);
        builder.set_lookup_bits(lookup_bits);
        let ctx = builder.main(0);
        let gate = halo2_base::gates::GateChip::default();
        
        // Compute Check
        let s = ctx.load_witness(secret);
        let n = ctx.load_witness(nonce);
        let e = ctx.load_witness(ext_nullifier);
        
        let mut sponge1 = PoseidonSponge::<Fr, 3, 2>::new::<8, 57, 0>(ctx);
        sponge1.update(&[s, n]);
        let comm = sponge1.squeeze(ctx, &gate);
        
        let mut sponge2 = PoseidonSponge::<Fr, 3, 2>::new::<8, 57, 0>(ctx);
        sponge2.update(&[s, e]);
        let null = sponge2.squeeze(ctx, &gate);
        
        let comm_val = *comm.value();
        let null_val = *null.value();
        
        // Build actual circuit
        let circuit = build_nullifier_circuit(
            CircuitBuilderStage::Mock,
            comm_val,
            null_val,
            ext_nullifier,
            secret,
            nonce,
            k,
            lookup_bits
        );
        
        let instances = circuit.instances();
        let prover = MockProver::run(k as u32, &circuit, instances).unwrap();
        if let Err(errs) = prover.verify() {
            println!("Verification failed with errors: {:?}", errs);
            panic!("Verification failed");
        }
    }
}
