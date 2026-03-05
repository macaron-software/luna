// LUNA — Noyau Rust partagé iOS + Android
//
// Aucun appel réseau. Aucune télémétrie. Données chiffrées AES-256-GCM.
// Bindings cross-platform via UniFFI (Swift + Kotlin auto-générés).

pub mod engine;
pub mod error;
pub mod vault;
pub mod api;

pub use engine::types::*;
pub use engine::prediction::CyclePhase;
pub use error::LunaError;
pub use api::LunaEngine;

uniffi::setup_scaffolding!();
