use thiserror::Error;

#[derive(Debug, Error, uniffi::Error)]
#[uniffi(flat_error)]
pub enum LunaError {
    #[error("PIN incorrect")]
    WrongPin,

    #[error("Base de données corrompue : {0}")]
    DatabaseCorrupted(String),

    #[error("Erreur de chiffrement : {0}")]
    CryptoError(String),

    #[error("Erreur I/O : {0}")]
    IoError(String),

    #[error("Données invalides : {0}")]
    InvalidData(String),

    #[error("Suppression complète effectuée")]
    WipedSuccessfully,

    #[error("Vault non initialisé — appelez open_vault() d'abord")]
    VaultNotOpen,

    #[error("Cycle introuvable : {0}")]
    CycleNotFound(String),
}

impl From<rusqlite::Error> for LunaError {
    fn from(e: rusqlite::Error) -> Self {
        LunaError::DatabaseCorrupted(e.to_string())
    }
}

impl From<serde_json::Error> for LunaError {
    fn from(e: serde_json::Error) -> Self {
        LunaError::InvalidData(e.to_string())
    }
}
