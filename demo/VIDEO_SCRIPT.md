# ZK-Gate Demo Video Script — 2:30 Duration
# Stellar Hacks: Real-World ZK Submission
# ============================================================
# Record with: OBS Studio (screen + window capture)
# Or: QuickTime (macOS) → New Screen Recording
# ============================================================

## TIMING BREAKDOWN

### [0:00-0:15] INTRO — Title Card (15s)
VISUAL: Open demo/index.html in browser — dark page visible
AUDIO: "ZK-Gate — Zero-Knowledge Identity Gating on Stellar."
       "Built for the Stellar Hacks Real-World ZK hackathon."
ACTION:  Slow scroll from hero to architecture overview

### [0:15-0:35] THE PROBLEM (20s)
VISUAL: Scroll to show the architecture diagram
AUDIO: "DeFi platforms need to verify user credentials — KYC, age,
       accreditation — before granting access. Today that means
       handing over personal documents to a centralized service.
       
       ZK-Gate eliminates this trade-off. Users prove they meet
       requirements via zero-knowledge proofs, and the blockchain
       verifies mathematically. No personal data ever leaves the device."
ACTION: Point at User → Noir → Soroban flow

### [0:35-1:05] THE DEMO — Interactive Walkthrough (30s)
VISUAL: Scroll to "Live Demo" section
ACTION: 
  1. Show user's private data panel (left side)
     - Point at: Age: 34, Jurisdiction: Singapore, KYC: Verified, Accreditation: Accredited
  2. Show gate requirements (below)
     - Point at: Min Age: 18, Min Accreditation: Retail, Jurisdictions: US,UK,EU,SG,CH
  
  3. Click "Generate ZK Proof" button
  
AUDIO: "Let's walk through the flow. Here's a user's private data —
       their actual age, jurisdiction, KYC status. These values
       NEVER leave the device.
       
       The gate requires a minimum age of 18, retail accreditation,
       and an approved jurisdiction. 
       
       When we generate the ZK proof, the Noir circuit produces a
       cryptographic proof that these requirements are met — without
       revealing any of the underlying values."

### [1:05-1:35] PROOF GENERATION ANIMATION (30s)
VISUAL: Watch the proof output populate:
  - Proof Size: 256 bytes (G1+G2+G1)
  - Proof Time: ~Xms
  - Proof hex appears
  
  Then public signals:
  - identity_commitment (truncated)
  - nullifier_hash (truncated)
  - credential_level: 3/3
  - epoch timestamp
  
  Then verification result:
  - "ACCESS GRANTED" with green badge
  - All 4 checks pass (pairing, nullifier, credential, commitment)

AUDIO: "The proof is just 256 bytes — three elliptic curve points.
       It was generated in milliseconds using Barretenberg.
       
       What the blockchain sees are only four public signals:
       an identity commitment hash, a nullifier to prevent reuse,
       an aggregate credential level of three out of three,
       and a freshness epoch.
       
       The Soroban contract verifies the proof using BN254 pairing
       checks — Stellar Protocol 26's native elliptic curve
       host functions make this verification cheap and fast.
       
       Access is granted. The user can now interact with gated
       DeFi functions. And at no point was their actual age,
       location, or KYC data revealed."

### [1:35-2:00] PRIVACY BREAKDOWN (25s)
VISUAL: Scroll to "Privacy: What Gets Revealed vs Hidden" section
AUDIO: "Let's break down the privacy guarantees.
       
       The verifier sees four public values — hashes and an
       aggregate level. Nothing that can be reversed to
       identify the user or their attributes.
       
       Everything else stays private: the exact age, which
       jurisdiction they're in, their personal KYC data,
       accreditation details, and the secret nonce that
       binds it all together."

### [2:00-2:20] TECH STACK (20s)
VISUAL: Scroll to Tech Stack section, then GitHub link
ACTION: Click through to GitHub repo
AUDIO: "Under the hood: Noir circuits for proof generation,
       Soroban smart contracts for on-chain verification,
       Stellar Protocol 26 BN254 native host functions,
       and Poseidon hashing for ZK-friendly operations.
       
       The full source code is on GitHub — Noir circuits,
       Rust contracts, web demo, and deployment scripts."

### [2:20-2:30] OUTRO (10s)
VISUAL: End on the repo page or back to demo hero
ACTION: Fade or cut
AUDIO: "ZK-Gate. Prove your credentials, protect your privacy."
       "Built for Stellar Hacks Real-World ZK."

## RECORDING NOTES

1. **Browser**: Chrome/Brave, 1280x720 window for clean capture
2. **Font size**: Cmd/Ctrl + to bump up text for readability
3. **Dark mode**: Keep the dark theme for visual appeal
4. **Smooth scrolling**: Use trackpad or smooth scroll for cinematic feel
5. **No mouse cursor**: In OBS, enable "Hide cursor" or edit post
6. **Resolution**: 1920x1080 output, scale browser to fill

## POST-PRODUCTION

1. Trim start/end (remove setup/teardown)
2. Add subtle zoom on key moments (proof generation, verification result)
3. Fade transitions between sections (0.3s crossfade)
4. Add subtle background music (ambient tech, low volume)
5. Export: H.264, 1080p, high bitrate for DoraHacks upload

## OPTIONAL: Second Take — Show Failure Case

After the success demo, reset and change inputs:
- Set age to 16 (below threshold)
- Click generate
- Show "ACCESS DENIED" red badge
- Demonstrate the ZK circuit correctly rejects invalid inputs
- Narrate: "If requirements aren't met, the proof simply
  won't generate — the circuit constraints are unsatisfiable."
