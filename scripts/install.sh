#!/usr/bin/env bash
# ============================================================
# ZK-Gate — Install All Dependencies
# ============================================================
# Installs Noir, Soroban CLI, and Stellar SDK
# Run this once on a fresh machine
# ============================================================

set -euo pipefail

echo "=========================================="
echo "  ZK-Gate — Installing Dependencies"
echo "=========================================="
echo ""

# --- 1. Install Noir (nargo) ---
echo "[1/4] Installing Noir compiler..."
if command -v nargo &>/dev/null; then
    echo "  ✓ nargo already installed: $(nargo --version)"
else
    curl -L https://apt.noir-lang.org/install.sh | sh
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null
    echo "  ✓ nargo installed: $(nargo --version)"
fi
echo ""

# --- 2. Install Soroban CLI ---
echo "[2/4] Installing Soroban CLI..."
if command -v soroban &>/dev/null; then
    echo "  ✓ soroban already installed: $(soroban --version)"
else
    cargo install soroban-cli --locked
    echo "  ✓ soroban installed: $(soroban --version)"
fi
echo ""

# --- 3. Install stellar-cli for contract deployment ---
echo "[3/4] Checking stellar-cli..."
if command -v stellar &>/dev/null; then
    echo "  ✓ stellar already installed: $(stellar --version)"
else
    cargo install stellar-cli --locked
    echo "  ✓ stellar installed: $(stellar --version)"
fi
echo ""

# --- 4. Verify Rust toolchain ---
echo "[4/4] Checking Rust toolchain..."
rustc --version
cargo --version
echo ""

echo "=========================================="
echo "  All dependencies installed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  ./scripts/setup.sh      # Generate keys and build"
echo "  ./scripts/full_demo.sh   # Run the full demo"
