#!/usr/bin/env bash
# ============================================================
# ZK-Gate — Setup: Build circuits and compile contracts
# ============================================================

set -euo pipefail

echo "=========================================="
echo "  ZK-Gate — Setup & Build"
echo "=========================================="

# --- 1. Compile Noir circuits ---
echo ""
echo "[1/3] Compiling Noir circuits..."
cd circuits
nargo compile
echo "  ✓ Circuit compiled — target/zk_gate.json generated"

# Generate verification key
echo "  Generating verification key..."
nargo vkey
echo "  ✓ Verification key: target/vkey.json"
cd ..
echo ""

# --- 2. Build Soroban contract ---
echo "[2/3] Building Soroban contract..."
cd contracts/zk-kyc-verifier
cargo build --target wasm32-unknown-unknown --release
echo "  ✓ Contract WASM: target/wasm32-unknown-unknown/release/zk_kyc_verifier.wasm"

# Optimize
echo "  Optimizing WASM..."
soroban optimize \
    --wasm target/wasm32-unknown-unknown/release/zk_kyc_verifier.wasm \
    -o target/zk_kyc_verifier.optimized.wasm
echo "  ✓ Optimized WASM: target/zk_kyc_verifier.optimized.wasm"
cd ..
echo ""

# --- 3. Generate test vectors ---
echo "[3/3] Generating test inputs..."
cd circuits
echo "  Generating proof for valid KYC user..."
nargo execute proof
echo "  ✓ Proof generated: target/proof.json"
echo "  ✓ Public inputs: target/public_inputs.json"
cd ..
echo ""

echo "=========================================="
echo "  Setup complete!"
echo "=========================================="
echo ""
echo "Generated artifacts:"
echo "  circuits/target/zk_gate.json       (circuit)"
echo "  circuits/target/vkey.json          (verification key)"
echo "  circuits/target/proof.json         (ZK proof)"
echo "  circuits/target/public_inputs.json (public signals)"
echo "  contracts/.../zk_kyc_verifier.optimized.wasm (contract)"
