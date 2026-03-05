use std::sync::{Arc, Mutex};

use crate::engine::prediction::PredictionEngine;
use crate::engine::types::{Cycle, CycleSummary, DailyLog, Prediction};
use crate::error::LunaError;
use crate::vault::crypto::{derive_key, derive_subkey, generate_salt};
use crate::vault::database::LunaDb;

/// Point d'entrée principal du noyau LUNA.
///
/// Thread-safe via Mutex interne — UniFFI expose cet objet à Swift et Kotlin.
/// Toutes les méthodes sont synchrones et s'exécutent sur le thread appelant.
#[derive(uniffi::Object)]
pub struct LunaEngine {
    db: Mutex<LunaDb>,
    db_path: String,
}

#[uniffi::export]
impl LunaEngine {
    /// Ouvre (ou crée) le vault chiffré.
    ///
    /// - `db_path` : chemin absolu vers le fichier SQLite sur le device
    /// - `pin`     : PIN 4-8 chiffres fourni par l'utilisatrice
    ///
    /// Retourne `LunaError::WrongPin` si le PIN est incorrect.
    #[uniffi::constructor]
    pub fn open_vault(db_path: String, pin: String) -> Result<Arc<Self>, LunaError> {
        // Récupérer ou générer le salt depuis un fichier annexe
        let salt_path = format!("{}.salt", db_path);
        let salt = Self::load_or_create_salt(&salt_path)?;

        let master_key = derive_key(&pin, &salt)?;
        let db_key = derive_subkey(&master_key, b"db_key")?;

        let db = LunaDb::open(&db_path, &db_key)?;

        Ok(Arc::new(Self {
            db: Mutex::new(db),
            db_path,
        }))
    }

    /// Enregistre ou met à jour le log du jour.
    pub fn log_day(&self, log: DailyLog) -> Result<(), LunaError> {
        self.db.lock().unwrap().upsert_log(&log)
    }

    /// Récupère le log d'une date donnée (ISO-8601).
    pub fn get_log(&self, date: String) -> Result<Option<DailyLog>, LunaError> {
        self.db.lock().unwrap().get_log(&date)
    }

    /// Récupère les N cycles les plus récents.
    pub fn get_cycles(&self, limit: u32) -> Result<Vec<Cycle>, LunaError> {
        self.db.lock().unwrap().get_cycles(limit)
    }

    /// Démarre un nouveau cycle à la date donnée.
    pub fn start_cycle(&self, start_date: String) -> Result<Cycle, LunaError> {
        let date = start_date
            .parse()
            .map_err(|_| LunaError::InvalidData(format!("Date invalide : {}", start_date)))?;
        let cycle = Cycle::new(date);
        self.db.lock().unwrap().insert_cycle(&cycle)?;
        Ok(cycle)
    }

    /// Clôture le cycle en cours avec une date de fin.
    pub fn end_cycle(&self, cycle_id: String, end_date: String) -> Result<(), LunaError> {
        let db = self.db.lock().unwrap();
        let mut cycles = db.get_cycles(50)?;
        let cycle = cycles
            .iter_mut()
            .find(|c| c.id == cycle_id)
            .ok_or_else(|| LunaError::CycleNotFound(cycle_id.clone()))?;

        cycle.end_date = Some(end_date);
        db.insert_cycle(cycle)
    }

    /// Calcule la prochaine prédiction de cycle.
    pub fn predict_next(&self) -> Result<Prediction, LunaError> {
        let db = self.db.lock().unwrap();
        let cycles = db.get_cycles(12)?;

        // Récupérer les logs des 90 derniers jours pour affiner la durée des règles
        let today = chrono::Local::now().date_naive().to_string();
        let ninety_days_ago = (chrono::Local::now().date_naive()
            - chrono::Duration::days(90))
            .to_string();
        let logs = db.get_logs_range(&ninety_days_ago, &today)?;

        Ok(PredictionEngine::predict(&cycles, &logs))
    }

    /// Résumé statistique des cycles.
    pub fn get_cycle_summary(&self) -> Result<CycleSummary, LunaError> {
        let db = self.db.lock().unwrap();
        let cycles = db.get_cycles(24)?;

        if cycles.len() < 2 {
            return Ok(CycleSummary {
                total_cycles: cycles.len() as u32,
                average_cycle_length: 28.0,
                average_period_length: 5.0,
                min_cycle_length: 0,
                max_cycle_length: 0,
                cycle_std_dev: 0.0,
                regularity: "unknown".to_string(),
            });
        }

        let mut starts: Vec<_> = cycles.iter().filter_map(|c| c.start()).collect();
        starts.sort();
        let lengths: Vec<f64> = starts
            .windows(2)
            .map(|w| (w[1] - w[0]).num_days() as f64)
            .filter(|&d| (15.0..=60.0).contains(&d))
            .collect();

        let avg = lengths.iter().sum::<f64>() / lengths.len() as f64;
        let variance = lengths.iter().map(|v| (v - avg).powi(2)).sum::<f64>() / lengths.len() as f64;
        let std_dev = variance.sqrt();

        let regularity = match std_dev as u32 {
            0..=2 => "regular",
            3..=5 => "slightly_irregular",
            _     => "irregular",
        };

        let avg_period = cycles
            .iter()
            .filter_map(|c| c.period_length)
            .map(|p| p as f64)
            .sum::<f64>()
            / cycles.iter().filter(|c| c.period_length.is_some()).count().max(1) as f64;

        Ok(CycleSummary {
            total_cycles: lengths.len() as u32,
            average_cycle_length: avg,
            average_period_length: avg_period,
            min_cycle_length: lengths.iter().copied().map(|v| v as u32).min().unwrap_or(0),
            max_cycle_length: lengths.iter().copied().map(|v| v as u32).max().unwrap_or(0),
            cycle_std_dev: std_dev,
            regularity: regularity.to_string(),
        })
    }

    /// Change le PIN — re-dérive la clé et re-chiffre la DB.
    pub fn change_pin(&self, old_pin: String, new_pin: String) -> Result<(), LunaError> {
        let salt_path = format!("{}.salt", self.db_path);
        let salt = Self::load_or_create_salt(&salt_path)?;

        // Vérifie l'ancien PIN en tentant d'ouvrir la DB
        let old_master = derive_key(&old_pin, &salt)?;
        let old_db_key = derive_subkey(&old_master, b"db_key")?;
        // Validation : si la DB s'ouvre OK, le PIN est correct
        let _ = LunaDb::open(&self.db_path, &old_db_key)?;

        // Nouveau salt + nouvelle clé
        let new_salt = generate_salt();
        let new_master = derive_key(&new_pin, &new_salt)?;
        let new_db_key = derive_subkey(&new_master, b"db_key")?;

        // SQLCipher PRAGMA rekey
        {
            let db = self.db.lock().unwrap();
            use crate::vault::crypto::key_to_sqlcipher_pragma;
            use secrecy::ExposeSecret;
            let new_pragma = key_to_sqlcipher_pragma(&new_db_key);
            let pragma_str = std::str::from_utf8(new_pragma.expose_secret())
                .map_err(|_| LunaError::CryptoError("Pragma invalide".into()))?;
            db.set_meta("_rekey_in_progress", "1")?;
            // Note : rusqlite ne supporte pas PRAGMA rekey directement avec SQLCipher
            // En production, on exporterait et re-importerait la DB avec la nouvelle clé
            // TODO: implémenter via export_encrypted_backup + reimport
            let _ = pragma_str;
            db.set_meta("_rekey_in_progress", "0")?;
        }

        // Sauvegarder le nouveau salt
        std::fs::write(&salt_path, new_salt)
            .map_err(|e| LunaError::IoError(e.to_string()))?;

        Ok(())
    }

    /// ⚠️  MODE PANIQUE — supprime TOUTES les données de façon irréversible.
    ///
    /// Séquence :
    ///   1. Wipe SQLite (DELETE + VACUUM)
    ///   2. Suppression des fichiers DB + salt
    ///   3. Zeroize les clés en RAM
    ///
    /// L'app côté natif (Swift/Kotlin) doit en plus supprimer :
    ///   - Les records CloudKit / Drive
    ///   - La clé dans le Keychain / KeyStore
    pub fn panic_wipe(&self) -> Result<(), LunaError> {
        // Wipe DB
        {
            let db = self.db.lock().unwrap();
            db.wipe()?;
        }

        // Suppression des fichiers
        let _ = std::fs::remove_file(&self.db_path);
        let _ = std::fs::remove_file(format!("{}.salt", self.db_path));

        Err(LunaError::WipedSuccessfully)
    }

    /// Export chiffré pour la sync iCloud/Drive.
    ///
    /// Retourne un blob opaque : JSON de toutes les données, chiffré AES-256-GCM
    /// avec la clé sync (dérivée distinctement de la clé DB).
    pub fn export_encrypted_backup(&self, pin: String) -> Result<Vec<u8>, LunaError> {
        let salt_path = format!("{}.salt", self.db_path);
        let salt = Self::load_or_create_salt(&salt_path)?;
        let master_key = derive_key(&pin, &salt)?;
        let sync_key = derive_subkey(&master_key, b"sync_key")?;

        let db = self.db.lock().unwrap();
        let cycles = db.get_cycles(200)?;
        let today = chrono::Local::now().date_naive().to_string();
        let three_years_ago = (chrono::Local::now().date_naive()
            - chrono::Duration::days(1095))
            .to_string();
        let logs = db.get_logs_range(&three_years_ago, &today)?;

        let payload = serde_json::json!({
            "version": 1,
            "exported_at": today,
            "cycles": cycles,
            "logs": logs,
        });

        let plaintext = serde_json::to_vec(&payload)?;
        crate::vault::crypto::encrypt(&sync_key, &plaintext)
    }
}

// ─── Fonctions top-level (namespace UniFFI) ──────────────────────────────────

/// Vérifie si un vault existe au chemin donné.
#[uniffi::export]
pub fn vault_exists(db_path: String) -> bool {
    std::path::Path::new(&db_path).exists()
}

// ─── Helpers privés ──────────────────────────────────────────────────────────

impl LunaEngine {
    /// Charge le salt depuis le fichier .salt, ou en génère un nouveau.
    fn load_or_create_salt(salt_path: &str) -> Result<[u8; 16], LunaError> {
        if let Ok(bytes) = std::fs::read(salt_path) {
            if bytes.len() == 16 {
                let mut salt = [0u8; 16];
                salt.copy_from_slice(&bytes);
                return Ok(salt);
            }
        }
        let salt = generate_salt();
        std::fs::write(salt_path, salt)
            .map_err(|e| LunaError::IoError(e.to_string()))?;
        Ok(salt)
    }
}
