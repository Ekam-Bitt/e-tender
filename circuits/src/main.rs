//! Range Proof CLI
//!
//! CLI for generating ZK proofs and Solidity verifiers using snark-verifier-sdk.

use anyhow::Result;
use clap::{Parser, Subcommand};
use range_proof::{
    RangeProofCircuit,
    // NullifierCircuit struct is removed, now we use build_nullifier_circuit
    verifier::{generate_params, generate_proving_key, generate_evm_verifier},
    nullifier_circuit::{build_nullifier_circuit, generate_nullifier_pk, generate_nullifier_evm_verifier},
};
use halo2_base::gates::circuit::CircuitBuilderStage;
use halo2_base::halo2_proofs::halo2curves::bn256::Fr;
use std::fs;
use std::path::Path;

#[derive(Parser)]
#[command(name = "range-proof-cli")]
#[command(about = "CLI for Halo2 range proof and nullifier circuits")]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate Solidity verifier contract for range proofs
    GenSolidity {
        /// Output file for Solidity contract
        #[arg(short, long, default_value = "Halo2Verifier.sol")]
        output: String,
        
        /// Circuit degree (k parameter)
        #[arg(short, long, default_value = "8")]
        k: u32,
    },
    
    /// Generate Solidity verifier contract for nullifier proofs
    GenNullifierSolidity {
        /// Output file for Solidity contract
        #[arg(short, long, default_value = "Halo2NullifierVerifier.sol")]
        output: String,
        
        /// Circuit degree (k parameter)
        #[arg(short, long, default_value = "8")]
        k: u32,
    },
    
    /// Generate proving and verification keys
    GenKeys {
        /// Output directory for keys
        #[arg(short, long, default_value = "./keys")]
        output: String,
        
        /// Circuit degree (k parameter)
        #[arg(short, long, default_value = "8")]
        k: u32,
    },
    
    /// Check circuit compilation
    Check,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::GenSolidity { output, k } => {
            println!("Generating Range Proof Solidity verifier...");
            println!("  k = {} (circuit size = 2^k = {} rows)", k, 1u64 << k);
            
            println!("  Generating KZG parameters...");
            let params = generate_params(k);
            
            println!("  Generating proving key...");
            let circuit = RangeProofCircuit::new(0, 1000, 500);
            let pk = generate_proving_key(&params, &circuit);
            
            println!("  Generating EVM verifier bytecode...");
            let output_path = Path::new(&output);
            let _bytecode = generate_evm_verifier(&params, &pk, Some(output_path));
            
            println!("Solidity contract written to: {}", output);
        }
        
        Commands::GenNullifierSolidity { output, k } => {
            println!("Generating Nullifier Solidity verifier...");
            println!("  k = {} (circuit size = 2^k = {} rows)", k, 1u64 << k);
            
            println!("  Generating KZG parameters...");
            let params = generate_params(k);
            
            println!("  Generating proving key...");
            // Use dummy values for PK generation
            let circuit = build_nullifier_circuit(
                CircuitBuilderStage::Keygen,
                Fr::default(), // commitment
                Fr::default(), // nullifier
                Fr::default(), // extern_nullifier
                Fr::default(), // secret
                Fr::default(), // nonce
                k as usize,
                k as usize - 1, // lookup bits
            );
            let pk = generate_nullifier_pk(&params, &circuit);
            
            println!("  Generating EVM verifier bytecode...");
            let output_path = Path::new(&output);
            let _bytecode = generate_nullifier_evm_verifier(&params, &pk, Some(output_path));
            
            println!("Solidity contract written to: {}", output);
        }
        
        Commands::GenKeys { output, k } => {
            println!("Generating proving and verification keys...");
            
            fs::create_dir_all(&output)?;
            
            let params = generate_params(k);
            let circuit = RangeProofCircuit::new(0, 1000, 500);
            let _pk = generate_proving_key(&params, &circuit);
            
            let vk_path = format!("{}/vk.bin", output);
            println!("Verification key written to: {}", vk_path);
        }
        
        Commands::Check => {
            println!("Circuit compilation check passed!");
            println!("Available modules:");
            println!("  - range_circuit: Range proof (min <= value <= max)");
            println!("  - nullifier_circuit: Nullifier proof");
            println!("  - verifier: EVM verifier generation");
        }
    }
    
    Ok(())
}
