# ZK-Gate Architecture

## System Overview

ZK-Gate implements a zero-knowledge identity gating system on Stellar. Users prove they meet credential requirements (KYC, age, accreditation, jurisdiction) without revealing the underlying personal data. The proof is generated off-chain using Noir circuits and verified on-chain by a Soroban smart contract using Stellar Protocol 26's native BN254 host functions.

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ZK-Gate System                          │
│                                                                 │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────────┐  │
│  │  User Device │    │  Noir Prover │    │  Stellar Network   │  │
│  │             │    │  (off-chain) │    │                    │  │
│  │  ┌────────┐ │    │ ┌──────────┐ │    │  ┌───────────────┐ │  │
│  │  │Private │ │    │ │Pedersen  │ │    │  │  Soroban      │ │  │
│  │  │Data    │──┼──▶│ │Commitment│ │    │  │  Contract     │ │  │
│  │  │        │ │    │ │          │ │    │  │               │ │  │
│  │  │ age    │ │    │ ├──────────┤ │    │  │  ┌──────────┐ │ │  │
│  │  │ loc    │ │    │ │Poseidon  │ │    │  │  │BN254     │ │ │  │
│  │  │ KYC    │ │    │ │Hash      │ │    │  │  │Pairing   │ │ │  │
│  │  │ accred │ │    │ ├──────────┤ │    │  │  │Check     │ │ │  │
│  │  │        │ │    │ │Range     │ │    │  │  └──────────┘ │ │  │
│  │  │ secret │ │    │ │Proof     │ │    │  │               │ │  │
│  │  └────────┘ │    │ ├──────────┤ │    │  │  ┌──────────┐ │ │  │
│  │             │    │ │Nullifier │ │    │  │  │Nullifier  │ │ │  │
│  └─────────────┘    │ │Derive    │ │    │  │  │Tracker    │ │ │  │
│                     │ └──────────┘ │    │  │  └──────────┘ │ │  │
│                     │              │    │  │               │ │  │
│                     │ ┌──────────┐ │    │  │  ┌──────────┐ │ │  │
│                     │ │Proof +   │──┼───▶│  │  │Gated     │ │ │  │
│                     │ │Public    │ │    │  │  │Access    │ │ │  │
│                     │ │Signals   │ │    │  │  │Control   │ │ │  │
│                     │ └──────────┘ │    │  │  └──────────┘ │ │  │
│                     └──────────────┘    │  └───────────────┘ │  │
│                                         └────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Phase 1: Registration (once per user)

```
User                        Stellar Network
  │                              │
  │  1. Generate secret nonce    │
  │  2. Compute Pedersen         │
  │     commitment:              │
  │     C = Ped(secret, data)    │
  │                              │
  │  ───── register_identity ───▶│
  │     {user, commitment}        │
  │                              │  3. Store commitment
  │                              │     in contract storage
  │  ◀─────── success ───────────│
  │                              │
```

### Phase 2: Proof Generation (per access request)

```
User Device                  Noir Prover
  │                              │
  │  Private inputs:             │
  │  - secret, age, loc,        │
  │    KYC, accreditation        │
  │                              │
  │  Public inputs:              │
  │  - min_age, min_accred,     │
  │    allowed_jurisdictions,     │
  │    epoch                     │
  │  ────── inputs ──────────────▶│
  │                              │
  │                         Constraint checks:
  │                         - age >= min_age
  │                         - jurisdiction in set
  │                         - KYC verified
  │                         - accreditation met
  │                         - commitment ownership
  │                         - nullifier derivation
  │                              │
  │  ◀──── proof + signals ──────│
  │                              │
  │  Output:
  │  - proof (256 bytes)
  │  - identity_commitment
  │  - nullifier_hash
  │  - credential_level
  │  - epoch
  │                              │
```

### Phase 3: On-Chain Verification

```
User                        Soroban Contract
  │                              │
  │  ── verify_proof ────────────▶│
  │  {proof, public_inputs,      │
  │   epoch}                     │
  │                              │
  │                         1. Validate public inputs
  │                         2. Check commitment matches
  │                         3. Check nullifier unused
  │                         4. BN254 pairing check:
  │                            e(A,B) == e(α,β)·e(L,γ)·e(C,δ)
  │                         5. Check proof freshness
  │                              │
  │  ◀─────── success ───────────│
  │                              │
  │  ── gated_action ────────────▶│
  │                              │  6. Check credential_level
  │  ◀─────── access ─────────────│  7. Emit AccessGranted event
  │                              │
```

## Cryptographic Primitives

### Pedersen Commitment
```
C = g^secret · h^H(data)
```
- Binds user data to a secret without revealing either
- Computationally hiding: commitment reveals nothing about data
- Perfectly binding: cannot open commitment to different values

### Poseidon Hash
```
H(x₀, x₁, ..., xₙ) → Field
```
- ZK-friendly hash (no lookup tables, no S-boxes)
- Used for: identity commitment, nullifier derivation, attestation hashing
- ~10x cheaper than SHA256 in ZK circuits

### BN254 Pairing Check (Stellar Protocol 26)
```
e(A, B) == e(α, β) · e(ΣIC_i·x_i, γ) · e(C, δ)
```
- Native host functions: ec_add_bn256, ec_mul_bn256, ec_pairing_check_bn256
- Moves EC math out of WASM into the host layer
- Makes Groth16/PLONK verification orders of magnitude cheaper

### Nullifier Scheme
```
nullifier = Poseidon(secret, salt, domain_separator)
```
- Deterministic: same user always produces same nullifier
- Cannot be linked to identity commitment without secret
- Contract tracks spent nullifiers to prevent double-use

## Security Properties

| Property | Mechanism |
|---|---|
| **Zero-knowledge** | Noir proof reveals only public signals, nothing about private inputs |
| **Soundness** | BN254 pairing check is computationally infeasible to forge |
| **Non-reputation** | User must know secret to generate valid proof |
| **Freshness** | Epoch-based proof expiration prevents stale proofs |
| **Double-spend prevention** | Nullifier tracking prevents proof reuse |
| **Unlinkability** | Nullifier cannot be linked to identity without secret |

## Credential Level System

| Level | Meaning | Required Checks |
|---|---|---|
| 0 | No clearance | — |
| 1 | Basic | age + KYC verified |
| 2 | Standard | age + KYC + jurisdiction |
| 3 | Full | age + KYC + jurisdiction + accreditation |

The level is computed inside the circuit (not revealed which individual checks passed) and output as a single public signal.

## Stellar Protocol 26 Integration

Protocol 26 ("Yardstick") added nine BN254 host functions to Soroban:

| Host Function | Purpose | Used In |
|---|---|---|
| `ec_add_bn256` | G1/G2 point addition | Verification accumulator |
| `ec_mul_bn256` | Scalar multiplication | Linear combination of IC |
| `ec_pairing_check_bn256` | Ate pairing check | Final verification equation |
| `scalar_add`, `scalar_mul`, `scalar_sub` | Field arithmetic | Intermediate computations |
| `scalar_inverse`, `scalar_negate` | Field operations | Proof deserialization |

These functions execute in the host layer (native Rust), bypassing the WASM metering. This makes ZK proof verification economically viable on Stellar for the first time.

## Future Work

- **Multi-issuer attestation**: Support multiple KYC providers with BLS aggregate signatures
- **Revocation**: Nullifier tree for efficient credential revocation
- **Threshold credentials**: Prove balance > X without revealing exact amount
- **Cross-chain**: Bridge ZK-Gate credentials between Stellar and other chains
- **Mobile SDK**: WASM-based Noir prover running in browser/mobile
- **Regulatory compliance**: Integration with specific jurisdiction requirements (MiCA, etc.)
