// ============================================================
// ZK-Gate Library — Utility functions for Noir circuits
// ============================================================

/// Hash an array of fields using Poseidon (standard 3-ary)
pub fn poseidon3(inputs: [Field; 3]) -> Field {
    std::hash::poseidon(inputs)
}

/// Hash an array of fields using Poseidon (4-ary)
pub fn poseidon4(inputs: [Field; 4]) -> Field {
    std::hash::poseidon(inputs)
}

/// Convert a boolean to a field (1 or 0)
pub fn bool_to_field(b: bool) -> Field {
    if b { 1 } else { 0 }
}

/// Convert a field to a boolean
pub fn field_to_bool(f: Field) -> bool {
    f != 0
}
