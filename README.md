# ZK-Gate — Zero-Knowledge Identity Gating on Stellar

[![Noir](https://img.shields.io/badge/Noir-ZK%20Circuits-purple)](https://noir-lang.org/)
[![Soroban](https://img.shields.io/badge/Soroban-Smart%20Contract-blue)](https://soroban.stellar.org/)
[![Stellar Protocol 26](https://img.shields.io/badge/Stellar-Protocol%2026%20BN254-orange)](https://developers.stellar.org/)
[![DoraHacks](https://img.shields.io/badge/DoraHacks-Stellar%20Hacks-green)](https://dorahacks.io/hackathon/stellar-hacks-zk)

> **Prove you meet identity requirements without revealing personal data.**
> Noir circuits generate ZK proofs off-chain; Soroban contracts verify them on-chain using Stellar Protocol 26's native BN254 host functions.

## The Problem

DeFi platforms, tokenized asset pools, and regulated financial products need to verify user credentials — KYC status, age, accreditation, jurisdiction — before granting access. Today this means handing over personal documents to a centralized service, creating honeypots of sensitive data.

**ZK-Gate eliminates this trade-off.** Users prove they meet requirements via cryptographic zero-knowledge proofs, and the blockchain verifies the proof mathematically — no personal data ever leaves the user's device.

## How It Works

```
┌──────────┐      ┌───────────────┐      ┌───────────────────┐
│          │      │               │      │                   │
│   User   │─────▶│  Noir Circuit │─────▶│  Soroban Contract │
│          │      │  (off-chain)  │      │  (on-chain)       │
│  Private │      │               │      │  BN254 pairing    │
│  Data    │      │  - Pedersen   │      │  - Verify proof   │
│          │      │  - Poseidon   │      │  - Check nullifier│
│  age: 34 │      │  - Range proof│      │  - Grant access   │
│  KYC: ✓  │      │  - Nullifier  │      │  - Gate functions │
│  loc: SG │      │               │      │                   │
└──────────┘      └───────────────┘      └───────────────────┘
                        │
                   ZK Proof (256 bytes)
                   + Public Signals (4 fields)
```

### What the verifier learns:

| Public Signal | Meaning | Privacy |
|---|---|---|
| `identity_commitment` | Hash of user identity | Cannot reverse to find identity |
| `nullifier_hash` | Unique proof ID | Prevents double-use, doesn't identify user |
| `credential_level` | Aggregate clearance (0-3) | Doesn't reveal which requirements were met |
| `epoch` | Proof timestamp | Proof freshness only |

### What stays private:

- Exact age (only proves `age >= threshold`)
- Jurisdiction (only proves membership in allowed set)
- KYC data (only proves verification status)
- Accreditation level (only proves minimum met)
- User's secret nonce

## Architecture

```
zk-gate/
├── circuits/                    # Noir ZK circuits
│   ├── Nargo.toml              # Noir package config
│   ├── Prover.toml             # Input file for proving
│   └── src/
│       ├── main.nr             # Main circuit: identity proof
│       └── lib.nr              # Utility functions
│
├── contracts/                   # Soroban smart contracts
│   └── zk-kyc-verifier/
│       ├── Cargo.toml
│       └── src/
│           └── lib.rs          # Contract: BN254 verifier + gated access
│
├── demo/
│   └── index.html              # Interactive web demo
│
├── scripts/
│   ├── install.sh              # Install dependencies
│   ├── setup.sh                # Build circuits + contract
│   └── full_demo.sh            # Full demo flow on testnet
│
└── README.md
```

### Key Design Decisions

**Noir over Circom/RISC Zero:** Stellar Protocol 25/26 added native BN254 elliptic-curve host functions (ec_add_bn256, ec_mul_bn256, ec_pairing_check_bn256) specifically optimized for Noir proof verification. This makes on-chain verification meaningfully cheaper compared to other proof systems.

**Pedersen + Poseidon over SHA256:** ZK-friendly primitives that enable efficient proof generation. Pedersen commitments bind user identity; Poseidon hashes derive nullifiers and attestation data.

**Nullifier-based double-spend prevention:** Each proof produces a deterministic nullifier from the user's secret + salt. The contract tracks spent nullifiers — reusing a proof is cryptographically impossible.

**Credential levels over binary pass/fail:** The circuit outputs a 0-3 credential level, enabling granular gating (e.g., retail vs. accredited vs. institutional access) without revealing which specific requirements the user met.

## Quick Start

### Prerequisites

```bash
# Install Noir compiler
curl -L https://apt.noir-lang.org/install.sh | sh

# Install Soroban CLI
cargo install soroban-cli --locked
```

### Build

```bash
git clone https://github.com/icohangar-ops/zk-gate.git
cd zk-gate

# Build everything
./scripts/setup.sh
```

### Run the Demo

```bash
# Open the web demo (no blockchain needed)
open demo/index.html

# Full on-chain demo (requires Stellar testnet account)
export STELLAR_SECRET_KEY=<your-secret-key>
./scripts/full_demo.sh
```

## Noir Circuit Details

The circuit (`circuits/src/main.nr`) takes:

**Private inputs:**
- `secret` — user's nonce for Pedersen commitment
- `user_age` — actual age (never revealed)
- `user_jurisdiction` — jurisdiction code (never revealed)
- `is_kyc_verified` — KYC status (never revealed)
- `accreditation_level` — accreditation tier (never revealed)
- `nullifier_salt` — salt for nullifier derivation

**Public inputs:**
- `min_age` — minimum age threshold
- `min_accreditation` — minimum accreditation required
- `allowed_jurisdictions_hash` — hash of allowed jurisdictions
- `current_epoch` — freshness timestamp

**The circuit proves (via constraints, not computation):**
1. User owns the registered identity commitment
2. `user_age >= min_age` (range proof)
3. Jurisdiction is in the allowed set (membership proof)
4. KYC is verified
5. Accreditation meets threshold
6. Nullifier is correctly derived

## Soroban Contract Details

The contract (`contracts/zk-kyc-verifier/src/lib.rs`) implements:

**Storage:**
- `IdentityCommitments` — user → Pedersen commitment mapping
- `Nullifiers` — spent nullifier set (prevents double-use)
- `CredentialLevels` — user → credential level mapping
- `VerificationKey` — BN254 Groth16/PLONK verification key

**Core functions:**
- `register_identity()` — stores Pedersen commitment
- `verify_proof()` — verifies ZK proof via BN254 pairing, checks nullifier, records credentials
- `check_access()` — returns credential level if sufficient
- `gated_action()` — example gated function (in production: DeFi pool, governance vote, etc.)
- `set_verification_key()` — admin sets the BN254 verification key

**BN254 Verification (Protocol 26):**

The verification equation for Groth16/PLONK is:
```
e(A, B) == e(α, β) · e(Σ(IC_i · x_i), γ) · e(C, δ)
```

Stellar Protocol 26 provides the native host functions:
- `ec_add_bn256` — point addition on G1/G2
- `ec_mul_bn256` — scalar multiplication
- `ec_pairing_check_bn256` — ate pairing check

These move the heavy elliptic-curve math into the host layer, making ZK proof verification orders of magnitude cheaper than computing in pure WASM.

## Real-World Applications

| Application | What ZK-Gate Proves | What's Hidden |
|---|---|---|
| **Regulated DeFi pools** | Investor is accredited | Net worth, income, location |
| **Tokenized securities** | Buyer meets KYC requirements | Identity documents, nationality |
| **Age-gated services** | User is over 18/21 | Exact birthdate, name |
| **Jurisdictional compliance** | User is in allowed region | Specific country, IP address |
| **Cross-border payments** | Sender meets AML requirements | Transaction details, balances |

## Submission Info

Built for **[Stellar Hacks: Real-World ZK](https://dorahacks.io/hackathon/stellar-hacks-zk)** — $10,000 prize pool.

- **Platform:** Stellar (Protocol 26 BN254)
- **ZK System:** Noir + Barretenberg
- **Smart Contracts:** Soroban (Rust)
- **Team:** cubiczan@icohangar.dev

## License

MIT
