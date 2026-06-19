#!/usr/bin/env bash
# ============================================================
# ZK-Gate — Full Demo Flow
# ============================================================
# Demonstrates the complete ZK identity gating pipeline:
#   1. Deploy contract to Stellar testnet
#   2. Register identity commitment
#   3. Generate ZK proof off-chain
#   4. Submit proof for on-chain verification
#   5. Access gated function
# ============================================================

set -euo pipefail

NETWORK="futurenet"
SECRET_KEY="${STELLAR_SECRET_KEY:-}"
CONTRACT_ID=""

echo "=========================================="
echo "  ZK-Gate — Full Demo"
echo "=========================================="

if [ -z "$SECRET_KEY" ]; then
    echo "⚠  STELLAR_SECRET_KEY not set"
    echo "  Run: export STELLAR_SECRET_KEY=<your-secret-key>"
    echo "  Get a key: stellar keys generate"
    exit 1
fi

# --- Step 1: Deploy contract ---
echo ""
echo "[Step 1] Deploying ZK-KYC Verifier contract..."
CONTRACT_ID=$(soroban deploy \
    --wasm contracts/zk-kyc-verifier/target/zk_kyc_verifier.optimized.wasm \
    --source "$SECRET_KEY" \
    --network "$NETWORK" \
    --rpc-url https://rpc.$NETWORK.stellar.org \
    | tail -1 | tr -d '[:space:]')
echo "  Contract ID: $CONTRACT_ID"

# Initialize
echo "  Initializing contract..."
ADMIN_ADDR=$(stellar keys address --secret-key "$SECRET_KEY")
soroban invoke \
    --source "$SECRET_KEY" \
    --network "$NETWORK" \
    --rpc-url https://rpc.$NETWORK.stellar.org \
    --contract-id "$CONTRACT_ID" \
    -- \
    initialize \
    --admin "$ADMIN_ADDR" \
    --required_level 1 \
    --max_epoch_age 86400
echo "  ✓ Contract initialized"
echo ""

# --- Step 2: Register identity ---
echo "[Step 2] Registering identity commitment..."
USER_ADDR=$(stellar keys address --secret-key "$SECRET_KEY")

# In production: compute commitment from user's secret + data
# For demo: use a fixed commitment
COMMITMENT="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

soroban invoke \
    --source "$SECRET_KEY" \
    --network "$NETWORK" \
    --rpc-url https://rpc.$NETWORK.stellar.org \
    --contract-id "$CONTRACT_ID" \
    -- \
    register_identity \
    --user "$USER_ADDR" \
    --commitment "$COMMITMENT"
echo "  ✓ Identity registered"
echo ""

# --- Step 3: Generate ZK proof ---
echo "[Step 3] Generating ZK proof off-chain..."
cd circuits
nargo execute proof
echo "  ✓ Proof generated"
cd ..
echo ""

# --- Step 4: Submit proof for verification ---
echo "[Step 4] Submitting proof for on-chain verification..."

# Extract proof and public inputs
PROOF_A=$(python3 -c "import json; p=json.load(open('circuits/target/proof.json')); print(p.get('a','0'))")
PROOF_B=$(python3 -c "import json; p=json.load(open('circuits/target/proof.json')); print(p.get('b','0'))")
PROOF_C=$(python3 -c "import json; p=json.load(open('circuits/target/proof.json')); print(p.get('c','0'))")

soroban invoke \
    --source "$SECRET_KEY" \
    --network "$NETWORK" \
    --rpc-url https://rpc.$NETWORK.stellar.org \
    --contract-id "$CONTRACT_ID" \
    -- \
    verify_proof \
    --user "$USER_ADDR" \
    --proof_a "$PROOF_A" \
    --proof_b "$PROOF_B" \
    --proof_c "$PROOF_C" \
    --public_inputs "$(cat circuits/target/public_inputs.json)" \
    --epoch $(date +%s)
echo "  ✓ Proof verified on-chain!"
echo ""

# --- Step 5: Access gated function ---
echo "[Step 5] Accessing gated function..."
soroban invoke \
    --source "$SECRET_KEY" \
    --network "$NETWORK" \
    --rpc-url https://rpc.$NETWORK.stellar.org \
    --contract-id "$CONTRACT_ID" \
    -- \
    gated_action \
    --user "$USER_ADDR"
echo "  ✓ Access granted!"
echo ""

# --- Verify state ---
echo "[Step 6] Verifying on-chain state..."
LEVEL=$(soroban invoke \
    --source "$SECRET_KEY" \
    --network "$NETWORK" \
    --rpc-url https://rpc.$NETWORK.stellar.org \
    --contract-id "$CONTRACT_ID" \
    -- \
    get_credential_level \
    --user "$USER_ADDR")
echo "  Credential level: $LEVEL"

echo ""
echo "=========================================="
echo "  Demo complete!"
echo "=========================================="
echo ""
echo "Contract: $CONTRACT_ID"
echo "Network: $NETWORK"
echo ""
echo "Try double-submitting the same proof to see nullifier rejection:"
echo "  Re-run Step 4 — it should fail with NullifierAlreadyUsed"
