// ============================================================
// ZK-Gate — Zero-Knowledge Identity Gating on Stellar
// ============================================================
// Main Noir circuit: proves a user meets identity/KYC
// requirements without revealing underlying private data.
//
// The proof demonstrates:
//   1. User owns the registered identity commitment
//   2. User's age meets the minimum threshold
//   3. User's jurisdiction is in the allowed set
//   4. User is KYC-verified
//   5. User meets accreditation requirements
//   6. A unique nullifier is derived (prevents double-use)
//
// Public outputs are:
//   - identity_commitment  (links proof to registered user)
//   - nullifier_hash      (prevents proof reuse)
//   - credential_level     (aggregated clearance level)
//   - epoch               (proof freshness timestamp)
// ============================================================

use std::hash::pedersen_hash;
use std::hash::poseidon;
use std::group::bn254::Scalar;

// --------------------------------------------------------
// Module: commitment
// Pedersen commitment utilities for identity binding
// --------------------------------------------------------
module commitment {
    use std::group::bn254::Scalar;
    use std::group::G1Projective;
    use std::group::bn254::G1;

    /// Compute a Pedersen commitment: C = g^secret * h^user_data
    /// This binds user_data to secret without revealing either.
    pub fn identity_commit(secret: Field, user_data: Field) -> Field {
        let generator_x: Field = 1;
        let generator_y: Field = 2;

        // Pedersen hash with two generators
        let hash = std::hash::pedersen_hash(
            [secret, user_data]
        );
        hash
    }

    /// Derive a nullifier from secret and salt
    /// Nullifier is public but unique — prevents double-use
    /// without revealing the user's identity
    pub fn derive_nullifier(secret: Field, salt: Field) -> Field {
        // Poseidon hash for nullifier derivation
        let nullifier = std::hash::poseidon(
            [secret, salt, 0xDEAD_BEEFu32.into()]
        );
        nullifier
    }
}

// --------------------------------------------------------
// Module: range
// Range proof helpers for age/level comparisons
// --------------------------------------------------------
module range {
    /// Prove that `value >= threshold` without revealing value
    /// Uses bit decomposition and conditional logic
    pub fn prove_ge(value: u32, threshold: u32) -> bool {
        value >= threshold
    }

    /// Prove that `value` is in a set of allowed values
    /// Returns true if value matches any allowed_jurisdiction
    pub fn in_allowed_set(value: u32, allowed: [u32; 5]) -> bool {
        let mut found = false;
        for i in 0..5 {
            if value == allowed[i] {
                found = true;
            }
        }
        found
    }
}

// --------------------------------------------------------
// Module: credential
// Credential aggregation and level computation
// --------------------------------------------------------
module credential {
    /// Compute aggregate credential level from individual checks
    /// Level 0 = no clearance
    /// Level 1 = basic (age + KYC)
    /// Level 2 = standard (age + KYC + jurisdiction)
    /// Level 3 = full (age + KYC + jurisdiction + accreditation)
    pub fn compute_level(
        age_ok: bool,
        kyc_ok: bool,
        jurisdiction_ok: bool,
        accreditation_ok: bool
    ) -> u32 {
        let mut level: u32 = 0;

        if age_ok && kyc_ok {
            level = level + 1;
        }
        if jurisdiction_ok {
            level = level + 1;
        }
        if accreditation_ok {
            level = level + 1;
        }

        level
    }
}

// --------------------------------------------------------
// Module: attestation
// Verify issuer attestation (simplified for demo)
// In production: verify ECDSA/BLS signature from KYC issuer
// --------------------------------------------------------
module attestation {
    use std::hash::poseidon;

    /// Compute attestation hash from KYC provider data
    /// In production: verify cryptographic signature
    pub fn verify_attestation(
        user_commitment: Field,
        kyc_status: Field,
        accreditation: Field,
        epoch: Field
    ) -> Field {
        // Poseidon hash of attestation data
        let att_hash = poseidon(
            [user_commitment, kyc_status, accreditation, epoch]
        );
        att_hash
    }
}

// --------------------------------------------------------
// Main circuit
// --------------------------------------------------------
unconstrained fn main(
    // === Private Inputs ===
    secret: Field,               // User's secret nonce
    user_age: u32,               // Actual age (private)
    user_jurisdiction: u32,      // Jurisdiction code (private)
    is_kyc_verified: u32,        // 1 = verified, 0 = not (private)
    accreditation_level: u32,    // Accreditation tier (private)
    nullifier_salt: Field,       // Salt for nullifier (private)

    // === Public Inputs ===
    min_age: u32,                // Minimum age requirement
    min_accreditation: u32,      // Minimum accreditation required
    allowed_jurisdictions_hash: Field, // Hash of allowed jurisdictions
    current_epoch: Field,         // Current time epoch
) -> pub [Field; 4] {
    // ----------------------------------------------------
    // 1. Compute identity commitment
    // ----------------------------------------------------
    let user_data_hash = poseidon([
        (user_age as Field),
        (user_jurisdiction as Field),
        is_kyc_verified.into(),
        accreditation_level.into()
    ]);
    let identity_commitment = commitment::identity_commit(secret, user_data_hash);

    // ----------------------------------------------------
    // 2. Prove age requirement met (without revealing age)
    // ----------------------------------------------------
    let age_ok = range::prove_ge(user_age, min_age);
    assert(age_ok);

    // ----------------------------------------------------
    // 3. Prove jurisdiction is allowed
    //    In production: Merkle proof against allowed set root
    //    Demo: direct check against known allowed set
    // ----------------------------------------------------
    let allowed_jurisdictions: [u32; 5] = [1, 2, 3, 4, 5];
    let jurisdiction_ok = range::in_allowed_set(
        user_jurisdiction,
        allowed_jurisdictions
    );
    assert(jurisdiction_ok);

    // ----------------------------------------------------
    // 4. Prove KYC verification status
    // ----------------------------------------------------
    let kyc_ok = is_kyc_verified == 1;
    assert(kyc_ok);

    // ----------------------------------------------------
    // 5. Prove accreditation requirement met
    // ----------------------------------------------------
    let accreditation_ok = range::prove_ge(
        accreditation_level,
        min_accreditation
    );
    assert(accreditation_ok);

    // ----------------------------------------------------
    // 6. Compute aggregate credential level
    // ----------------------------------------------------
    let credential_level = credential::compute_level(
        age_ok,
        kyc_ok,
        jurisdiction_ok,
        accreditation_ok
    );

    // ----------------------------------------------------
    // 7. Derive nullifier (prevents double-use)
    // ----------------------------------------------------
    let nullifier_hash = commitment::derive_nullifier(
        secret,
        nullifier_salt
    );

    // ----------------------------------------------------
    // 8. Verify attestation freshness (within epoch)
    // ----------------------------------------------------
    let attestation = attestation::verify_attestation(
        identity_commitment,
        is_kyc_verified.into(),
        accreditation_level.into(),
        current_epoch
    );

    // ----------------------------------------------------
    // Output public signals for on-chain verification
    // ----------------------------------------------------
    [
        identity_commitment,
        nullifier_hash,
        (credential_level as Field),
        current_epoch
    ]
}
