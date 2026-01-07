//! Range Proof CLI
//!
//! Command-line tool for generating and verifying range proofs.
//!
//! Usage:
//!   range-proof-cli generate-keys --output ./keys
//!   range-proof-cli prove --min 10 --max 100 --value 50 --output proof.bin
//!   range-proof-cli verify --proof proof.bin --min 10 --max 100 --value 50
//!   range-proof-cli gen-solidity --output Halo2Verifier.sol

use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use range_proof::{RangeProofCircuit, verifier_sol::{ProvingSystem, generate_solidity_verifier}};
use range_proof::merkle_circuit::MerkleCircuit;
use halo2_proofs::{
    circuit::Value,
    plonk::{keygen_vk, keygen_pk},
    poly::commitment::Params,
};
use halo2curves::bn256::{Fr, Bn256, G1Affine};
use rand::rngs::OsRng;
use std::fs;
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "range-proof-cli")]
#[command(about = "CLI for Halo2 range proof generation and verification")]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate proving and verification keys
    GenerateKeys {
        /// Output directory for keys
        #[arg(short, long, default_value = "./keys")]
        output: PathBuf,
    },
    
    /// Generate a proof for a range claim
    Prove {
        /// Minimum allowed value
        #[arg(long)]
        min: u64,
        
        /// Maximum allowed value
        #[arg(long)]
        max: u64,
        
        /// Value to prove
        #[arg(long)]
        value: u64,
        
        /// Output file for proof
        #[arg(short, long, default_value = "proof.bin")]
        output: PathBuf,
    },
    
    /// Verify a proof
    Verify {
        /// Path to proof file
        #[arg(short, long)]
        proof: PathBuf,
        
        /// Minimum value (public input)
        #[arg(long)]
        min: u64,
        
        /// Maximum value (public input)
        #[arg(long)]
        max: u64,
        
        /// Value (public input)
        #[arg(long)]
        value: u64,
    },
    
    /// Generate Solidity verifier contract
    GenSolidity {
        /// Output file for Solidity contract
        #[arg(short, long, default_value = "Halo2Verifier.sol")]
        output: PathBuf,
    },
    
    /// Output proof as hex (for use in Solidity tests)
    ProveHex {
        /// Minimum allowed value
        #[arg(long)]
        min: u64,
        
        /// Maximum allowed value
        #[arg(long)]
        max: u64,
        
        /// Value to prove
        #[arg(long)]
        value: u64,
    },

    /// Generate Solidity Merkle verifier from the Rust circuit
    GenSolidityMerkle {
        /// Output file
        #[arg(short, long, default_value = "Halo2MerkleVerifier.sol")]
        output: PathBuf,
    },

    /// Generate Merkle Proof (Mock for now, creates dummy proof)
    ProveMerkle {
        /// Leaf value
        #[arg(long)]
        leaf: u64,
        /// Root value
        #[arg(long)]
        root: u64,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::GenerateKeys { output } => {
            println!("Generating proving and verification keys...");
            println!("This may take a moment...");
            
            let system = ProvingSystem::new();
            
            // Create output directory
            fs::create_dir_all(&output)?;
            
            // Export verification key
            let vk_bytes = system.export_vk();
            let vk_path = output.join("verification_key.bin");
            fs::write(&vk_path, &vk_bytes)?;
            
            println!("Keys generated successfully!");
            println!("  Verification key: {}", vk_path.display());
        }
        
        Commands::Prove { min, max, value, output } => {
            // Validate range
            if value < min || value > max {
                anyhow::bail!("Value {} is not in range [{}, {}]", value, min, max);
            }
            
            println!("Generating proof for: {} in [{}, {}]", value, min, max);
            
            let system = ProvingSystem::new();
            let circuit = RangeProofCircuit::new(value, min, max);
            
            let proof = system.prove(&circuit);
            
            fs::write(&output, &proof)?;
            println!("Proof written to: {}", output.display());
            println!("Proof size: {} bytes", proof.len());
        }
        
        Commands::Verify { proof: proof_path, min, max, value } => {
            println!("Verifying proof...");
            
            let proof = fs::read(&proof_path)
                .context("Failed to read proof file")?;
            
            let system = ProvingSystem::new();
            let circuit = RangeProofCircuit::new(value, min, max);
            let instances = circuit.instances();
            
            if system.verify(&proof, &instances) {
                println!("✓ Proof is VALID");
                println!("  Verified: {} is in range [{}, {}]", value, min, max);
            } else {
                println!("✗ Proof is INVALID");
                std::process::exit(1);
            }
        }
        
        Commands::GenSolidity { output } => {
            println!("Generating Solidity verifier contract...");
            
            let system = ProvingSystem::new();
            let vk_bytes = system.export_vk();
            
            let solidity_code = generate_solidity_verifier(&vk_bytes);
            
            fs::write(&output, &solidity_code)?;
            println!("Solidity contract written to: {}", output.display());
        }
        
        Commands::ProveHex { min, max, value } => {
            // Validate range
            if value < min || value > max {
                anyhow::bail!("Value {} is not in range [{}, {}]", value, min, max);
            }
            
            let system = ProvingSystem::new();
            let circuit = RangeProofCircuit::new(value, min, max);
            
            let proof = system.prove(&circuit);
            
            // Output as hex for Solidity tests
            println!("0x{}", hex::encode(&proof));
        }

        Commands::GenSolidityMerkle { output } => {
            println!("Generating Solidity Merkle verifier...");
            
            // 1. Setup Params
            let k = 8;
            let circuit = MerkleCircuit::default();

            // Attempt to create Params with explicit type
            let params: Params<G1Affine> = Params::new(k);
            let vk = keygen_vk(&params, &circuit).expect("keygen_vk failed");
            
            // Fallback: Use Debug representation to get unique bytes for the circuit
            // This ensures the VK hash changes if the circuit changes.
            let vk_bytes = format!("{:?}", vk).into_bytes();
            
            let solidity_code = generate_solidity_verifier(&vk_bytes);
            
            // Rename the contract in the source code to Halo2MerkleVerifier
            let solidity_code = solidity_code.replace("contract Halo2Verifier", "contract Halo2MerkleVerifier");
            
            fs::write(&output, &solidity_code)?;
            println!("Merkle Verifier written to: {}", output.display());
        }

        Commands::ProveMerkle { leaf, root } => {
             // Demo proof generation
             println!("Generating Merkle Proof for {} in root {}", leaf, root);
             // TODO: impl real proof
             println!("0x1234");
        }
    }
    
    Ok(())
}
