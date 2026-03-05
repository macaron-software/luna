use rusqlite::{params, Connection};
use secrecy::{ExposeSecret, SecretVec};

use crate::engine::types::{Cycle, DailyLog};
use crate::error::LunaError;
use crate::vault::crypto::key_to_sqlcipher_pragma;

/// Couche base de données — SQLite chiffrée via SQLCipher.
///
/// La clé est injectée via PRAGMA key immédiatement après l'ouverture
/// de la connexion — avant toute autre opération.
pub struct LunaDb {
    conn: Connection,
}

impl LunaDb {
    /// Ouvre (ou crée) la base chiffrée au chemin donné.
    ///
    /// `db_key` : clé 32 bytes dérivée par HKDF depuis la clé maître.
    pub fn open(path: &str, db_key: &SecretVec<u8>) -> Result<Self, LunaError> {
        let conn = Connection::open(path)
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        // Déverrouillage SQLCipher — doit être la PREMIÈRE opération
        let pragma = key_to_sqlcipher_pragma(db_key);
        let pragma_str = std::str::from_utf8(pragma.expose_secret())
            .map_err(|_| LunaError::CryptoError("Pragma UTF-8 invalide".into()))?;

        conn.execute_batch(&format!("PRAGMA key = \"{}\";", pragma_str))
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        // Vérifie que la DB est bien déchiffrée (mauvaise clé = erreur ici)
        conn.execute_batch("SELECT count(*) FROM sqlite_master;")
            .map_err(|_| LunaError::WrongPin)?;

        let db = Self { conn };
        db.run_migrations()?;
        Ok(db)
    }

    /// Migrations versionnées — toujours additive, jamais destructive.
    fn run_migrations(&self) -> Result<(), LunaError> {
        self.conn.execute_batch("
            PRAGMA journal_mode = WAL;
            PRAGMA foreign_keys = ON;
            PRAGMA secure_delete = ON;

            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY
            );

            CREATE TABLE IF NOT EXISTS cycles (
                id            TEXT PRIMARY KEY,
                start_date    TEXT NOT NULL,
                end_date      TEXT,
                period_length INTEGER,
                notes         TEXT,
                created_at    TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS daily_logs (
                id              TEXT PRIMARY KEY,
                date            TEXT NOT NULL UNIQUE,
                symptoms        TEXT NOT NULL DEFAULT '[]',
                mood            INTEGER,
                energy          INTEGER,
                bbt             REAL,
                lh_test         TEXT,
                cervical_mucus  TEXT,
                sexual_activity TEXT,
                flow            TEXT,
                notes           TEXT,
                created_at      TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS meta (
                key   TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_cycles_start ON cycles(start_date);
            CREATE INDEX IF NOT EXISTS idx_logs_date    ON daily_logs(date);
        ")
        .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        // Insérer la version si absente
        self.conn.execute(
            "INSERT OR IGNORE INTO schema_version (version) VALUES (1)",
            [],
        ).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        Ok(())
    }

    // ─── Cycles ──────────────────────────────────────────────────────────────

    pub fn insert_cycle(&self, cycle: &Cycle) -> Result<(), LunaError> {
        self.conn.execute(
            "INSERT OR REPLACE INTO cycles (id, start_date, end_date, period_length, notes, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, datetime('now'))",
            params![
                cycle.id,
                cycle.start_date,
                cycle.end_date,
                cycle.period_length.map(|p| p as i64),
                cycle.notes,
            ],
        ).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        Ok(())
    }

    pub fn get_cycles(&self, limit: u32) -> Result<Vec<Cycle>, LunaError> {
        let mut stmt = self.conn
            .prepare("SELECT id, start_date, end_date, period_length, notes FROM cycles ORDER BY start_date DESC LIMIT ?1")
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        let cycles = stmt.query_map(params![limit], |row| {
            Ok(Cycle {
                id: row.get(0)?,
                start_date: row.get(1)?,
                end_date: row.get(2)?,
                period_length: row.get::<_, Option<i64>>(3)?.map(|v| v as u8),
                notes: row.get(4)?,
            })
        })
        .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        Ok(cycles)
    }

    // ─── DailyLogs ───────────────────────────────────────────────────────────

    pub fn upsert_log(&self, log: &DailyLog) -> Result<(), LunaError> {
        let symptoms_json = serde_json::to_string(&log.symptoms)?;

        self.conn.execute(
            "INSERT INTO daily_logs (id, date, symptoms, mood, energy, bbt, lh_test, cervical_mucus, sexual_activity, flow, notes, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, datetime('now'))
             ON CONFLICT(date) DO UPDATE SET
               symptoms=excluded.symptoms, mood=excluded.mood, energy=excluded.energy,
               bbt=excluded.bbt, lh_test=excluded.lh_test, cervical_mucus=excluded.cervical_mucus,
               sexual_activity=excluded.sexual_activity, flow=excluded.flow,
               notes=excluded.notes, updated_at=datetime('now')",
            params![
                log.id, log.date, symptoms_json,
                log.mood.map(|v| v as i64), log.energy.map(|v| v as i64),
                log.bbt, log.lh_test, log.cervical_mucus,
                log.sexual_activity, log.flow, log.notes,
            ],
        ).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        Ok(())
    }

    pub fn get_log(&self, date: &str) -> Result<Option<DailyLog>, LunaError> {
        let mut stmt = self.conn
            .prepare("SELECT id, date, symptoms, mood, energy, bbt, lh_test, cervical_mucus, sexual_activity, flow, notes FROM daily_logs WHERE date = ?1")
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        let mut rows = stmt.query_map(params![date], |row| {
            let symptoms_json: String = row.get(2)?;
            Ok((row.get(0)?, row.get(1)?, symptoms_json,
                row.get(3)?, row.get(4)?, row.get(5)?,
                row.get(6)?, row.get(7)?, row.get(8)?,
                row.get(9)?, row.get(10)?))
        }).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        if let Some(row) = rows.next() {
            type LogRow = (String, String, String,
                Option<i64>, Option<i64>, Option<f64>,
                Option<String>, Option<String>, Option<String>,
                Option<String>, Option<String>);
            let (id, date, symptoms_json, mood, energy, bbt, lh_test,
                 cervical_mucus, sexual_activity, flow, notes): LogRow
                = row.map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

            let symptoms: Vec<String> = serde_json::from_str(&symptoms_json)
                .unwrap_or_default();

            Ok(Some(DailyLog {
                id,
                date,
                symptoms,
                mood: mood.map(|v| v as u8),
                energy: energy.map(|v| v as u8),
                bbt,
                lh_test,
                cervical_mucus,
                sexual_activity,
                flow,
                notes,
            }))
        } else {
            Ok(None)
        }
    }

    pub fn get_logs_range(&self, from: &str, to: &str) -> Result<Vec<DailyLog>, LunaError> {
        let mut stmt = self.conn
            .prepare("SELECT id, date, symptoms, mood, energy, bbt, lh_test, cervical_mucus, sexual_activity, flow, notes FROM daily_logs WHERE date BETWEEN ?1 AND ?2 ORDER BY date")
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        let logs = stmt.query_map(params![from, to], |row| {
            let symptoms_json: String = row.get(2)?;
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?, symptoms_json,
                row.get::<_, Option<i64>>(3)?, row.get::<_, Option<i64>>(4)?,
                row.get::<_, Option<f64>>(5)?, row.get::<_, Option<String>>(6)?,
                row.get::<_, Option<String>>(7)?, row.get::<_, Option<String>>(8)?,
                row.get::<_, Option<String>>(9)?, row.get::<_, Option<String>>(10)?))
        })
        .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?
        .filter_map(|r| r.ok())
        .map(|(id, date, symptoms_json, mood, energy, bbt, lh_test,
               cervical_mucus, sexual_activity, flow, notes)| {
            let symptoms = serde_json::from_str(&symptoms_json).unwrap_or_default();
            DailyLog { id, date, symptoms, mood: mood.map(|v| v as u8),
                       energy: energy.map(|v| v as u8), bbt, lh_test,
                       cervical_mucus, sexual_activity, flow, notes }
        })
        .collect();

        Ok(logs)
    }

    // ─── Meta ─────────────────────────────────────────────────────────────────

    pub fn set_meta(&self, key: &str, value: &str) -> Result<(), LunaError> {
        self.conn.execute(
            "INSERT OR REPLACE INTO meta (key, value) VALUES (?1, ?2)",
            params![key, value],
        ).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        Ok(())
    }

    pub fn get_meta(&self, key: &str) -> Result<Option<String>, LunaError> {
        let mut stmt = self.conn
            .prepare("SELECT value FROM meta WHERE key = ?1")
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        let mut rows = stmt.query_map(params![key], |r| r.get(0))
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        Ok(rows.next().and_then(|r| r.ok()))
    }

    // ─── Wipe ─────────────────────────────────────────────────────────────────

    /// Supprime toutes les données de façon sécurisée.
    /// VACUUM réécrit le fichier — aucun résidu en clair sur le disque.
    pub fn wipe(&self) -> Result<(), LunaError> {
        self.conn.execute_batch("
            DELETE FROM daily_logs;
            DELETE FROM cycles;
            DELETE FROM meta;
            DELETE FROM schema_version;
            VACUUM;
        ")
        .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        Ok(())
    }
}
