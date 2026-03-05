use aes_gcm::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};
use argon2::{Algorithm, Argon2, Params, Version};
use secrecy::{ExposeSecret, SecretVec};
use zeroize::Zeroize;

use crate::error::LunaError;

// ─── Paramètres Argon2id ────────────────────────────────────────────────────
// Calibrés pour un appareil mobile mid-range (~300ms)
const ARGON2_M_COST: u32 = 65536; // 64 MB
const ARGON2_T_COST: u32 = 3;     // 3 iterations
const ARGON2_P_COST: u32 = 4;     // 4 threads parallèles
const ARGON2_OUTPUT_LEN: usize = 32; // 256 bits = clé AES-256

// Salt fixe pour la dérivation DB (différent du salt sync)
// Stocké en clair dans la DB (ne protège pas la clé seule)
pub const SALT_LEN: usize = 16;
pub const NONCE_LEN: usize = 12;

/// Dérive une clé 256-bit depuis un PIN et un salt via Argon2id.
///
/// Le salt doit être généré aléatoirement à l'initialisation du vault
/// et stocké dans la DB (en clair — le secret reste le PIN).
pub fn derive_key(pin: &str, salt: &[u8; SALT_LEN]) -> Result<SecretVec<u8>, LunaError> {
    let params = Params::new(ARGON2_M_COST, ARGON2_T_COST, ARGON2_P_COST, Some(ARGON2_OUTPUT_LEN))
        .map_err(|e| LunaError::CryptoError(e.to_string()))?;

    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, params);

    let mut key_bytes = vec![0u8; ARGON2_OUTPUT_LEN];
    argon2
        .hash_password_into(pin.as_bytes(), salt, &mut key_bytes)
        .map_err(|e| LunaError::CryptoError(e.to_string()))?;

    Ok(SecretVec::new(key_bytes))
}

/// Dérive une sous-clé depuis la clé maître via HKDF-SHA256.
///
/// Chaque usage (DB, sync) obtient une clé dérivée distincte —
/// compromission d'une clé ne compromet pas les autres.
pub fn derive_subkey(
    master_key: &SecretVec<u8>,
    context: &[u8], // b"db_key" ou b"sync_key"
) -> Result<SecretVec<u8>, LunaError> {
    use ring::hkdf;

    let salt = hkdf::Salt::new(hkdf::HKDF_SHA256, b"luna-hkdf-salt-v1");
    let prk = salt.extract(master_key.expose_secret());
    let info = [context];
    let okm = prk
        .expand(&info, hkdf::HKDF_SHA256)
        .map_err(|_| LunaError::CryptoError("HKDF expand failed".into()))?;

    let mut subkey = vec![0u8; 32];
    okm.fill(&mut subkey)
        .map_err(|_| LunaError::CryptoError("HKDF fill failed".into()))?;

    Ok(SecretVec::new(subkey))
}

/// Chiffre `plaintext` avec AES-256-GCM.
///
/// Format de sortie : nonce (12 bytes) || ciphertext+tag
/// Le nonce est généré aléatoirement via CSPRNG (jamais réutilisé).
pub fn encrypt(key: &SecretVec<u8>, plaintext: &[u8]) -> Result<Vec<u8>, LunaError> {
    let cipher = Aes256Gcm::new_from_slice(key.expose_secret())
        .map_err(|_| LunaError::CryptoError("Clé invalide".into()))?;

    let nonce = Aes256Gcm::generate_nonce(&mut OsRng);
    let ciphertext = cipher
        .encrypt(&nonce, plaintext)
        .map_err(|_| LunaError::CryptoError("Échec du chiffrement".into()))?;

    // nonce || ciphertext
    let mut output = Vec::with_capacity(NONCE_LEN + ciphertext.len());
    output.extend_from_slice(&nonce);
    output.extend_from_slice(&ciphertext);
    Ok(output)
}

/// Déchiffre un blob produit par `encrypt()`.
pub fn decrypt(key: &SecretVec<u8>, blob: &[u8]) -> Result<Vec<u8>, LunaError> {
    if blob.len() < NONCE_LEN {
        return Err(LunaError::CryptoError("Blob trop court".into()));
    }

    let (nonce_bytes, ciphertext) = blob.split_at(NONCE_LEN);
    let nonce = Nonce::from_slice(nonce_bytes);

    let cipher = Aes256Gcm::new_from_slice(key.expose_secret())
        .map_err(|_| LunaError::CryptoError("Clé invalide".into()))?;

    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|_| LunaError::CryptoError("Déchiffrement échoué — PIN incorrect ou données corrompues".into()))
}

/// Génère un salt aléatoire via CSPRNG.
pub fn generate_salt() -> [u8; SALT_LEN] {
    use ring::rand::{SecureRandom, SystemRandom};
    let rng = SystemRandom::new();
    let mut salt = [0u8; SALT_LEN];
    rng.fill(&mut salt).expect("CSPRNG non disponible");
    salt
}

/// Sérialise la clé DB en hex pour PRAGMA key (SQLCipher).
///
/// Format SQLCipher : `PRAGMA key = "x'<hex>'"` 
pub fn key_to_sqlcipher_pragma(key: &SecretVec<u8>) -> SecretVec<u8> {
    let hex: String = key
        .expose_secret()
        .iter()
        .map(|b| format!("{:02x}", b))
        .collect();
    let pragma = format!("x'{}'", hex);
    SecretVec::new(pragma.into_bytes())
}

/// Efface de la mémoire un vecteur d'octets sensible.
pub fn secure_zero(data: &mut Vec<u8>) {
    data.zeroize();
}

// ─── Tests ──────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let salt = generate_salt();
        let key = derive_key("123456", &salt).unwrap();
        let plaintext = b"donnees_test_sensibles";

        let ciphertext = encrypt(&key, plaintext).unwrap();
        assert_ne!(&ciphertext, plaintext);

        let decrypted = decrypt(&key, &ciphertext).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_wrong_key_fails_decryption() {
        let salt = generate_salt();
        let key1 = derive_key("123456", &salt).unwrap();
        let key2 = derive_key("999999", &salt).unwrap();

        let ciphertext = encrypt(&key1, b"secret").unwrap();
        assert!(decrypt(&key2, &ciphertext).is_err());
    }

    #[test]
    fn test_nonce_uniqueness() {
        let salt = generate_salt();
        let key = derive_key("123456", &salt).unwrap();

        let c1 = encrypt(&key, b"data").unwrap();
        let c2 = encrypt(&key, b"data").unwrap();

        // Les 12 premiers bytes (nonce) doivent être différents
        assert_ne!(&c1[..NONCE_LEN], &c2[..NONCE_LEN], "Nonces identiques — violation de sécurité");
    }

    #[test]
    fn test_subkey_derivation_is_deterministic() {
        let salt = generate_salt();
        let master = derive_key("123456", &salt).unwrap();

        let db_key1 = derive_subkey(&master, b"db_key").unwrap();
        let db_key2 = derive_subkey(&master, b"db_key").unwrap();
        assert_eq!(db_key1.expose_secret(), db_key2.expose_secret());

        let sync_key = derive_subkey(&master, b"sync_key").unwrap();
        assert_ne!(db_key1.expose_secret(), sync_key.expose_secret(), "Sous-clés identiques");
    }

    #[test]
    fn test_argon2_different_pins_give_different_keys() {
        let salt = generate_salt();
        let k1 = derive_key("123456", &salt).unwrap();
        let k2 = derive_key("654321", &salt).unwrap();
        assert_ne!(k1.expose_secret(), k2.expose_secret());
    }
}
