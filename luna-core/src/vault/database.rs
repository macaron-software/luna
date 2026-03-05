use rusqlite::{params, Connection};
use secrecy::{ExposeSecret, SecretVec};

use crate::engine::types::{Cycle, DailyLog, UserProfile, PregnancyLog, TrackingMode, ContraceptionType};
use crate::error::LunaError;
use crate::vault::crypto::{compress_blob, decompress_blob, key_to_sqlcipher_pragma};

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
                symptoms        BLOB NOT NULL DEFAULT X'',
                mood            INTEGER,
                energy          INTEGER,
                bbt             REAL,
                lh_test         TEXT,
                cervical_mucus  TEXT,
                sexual_activity TEXT,
                flow            TEXT,
                sleep_quality   INTEGER,
                weight_kg       REAL,
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

            CREATE TABLE IF NOT EXISTS user_profile (
                id              INTEGER PRIMARY KEY CHECK (id = 1),
                tracking_mode   TEXT NOT NULL DEFAULT 'regular',
                contraception   TEXT NOT NULL DEFAULT 'none',
                pill_reminder   TEXT,
                notif_period    INTEGER NOT NULL DEFAULT 1,
                notif_fertile   INTEGER NOT NULL DEFAULT 0,
                notif_pill      INTEGER NOT NULL DEFAULT 0,
                edd             TEXT,
                calm_mode       INTEGER NOT NULL DEFAULT 0,
                health_sync     INTEGER NOT NULL DEFAULT 0,
                updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS pregnancy_logs (
                id           TEXT PRIMARY KEY,
                date         TEXT NOT NULL UNIQUE,
                hcg_positive INTEGER,
                kicks        INTEGER,
                nausea_level INTEGER,
                weight_kg    REAL,
                symptoms     BLOB NOT NULL DEFAULT X'',
                notes        TEXT,
                created_at   TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE INDEX IF NOT EXISTS idx_pregnancy_date ON pregnancy_logs(date);
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
        // Sérialisation JSON → compression zstd → BLOB binaire chiffré par SQLCipher
        let symptoms_blob = compress_blob(&serde_json::to_vec(&log.symptoms)?)?;

        self.conn.execute(
            "INSERT INTO daily_logs (id, date, symptoms, mood, energy, bbt, lh_test, cervical_mucus, sexual_activity, flow, sleep_quality, weight_kg, notes, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, datetime('now'))
             ON CONFLICT(date) DO UPDATE SET
               symptoms=excluded.symptoms, mood=excluded.mood, energy=excluded.energy,
               bbt=excluded.bbt, lh_test=excluded.lh_test, cervical_mucus=excluded.cervical_mucus,
               sexual_activity=excluded.sexual_activity, flow=excluded.flow,
               sleep_quality=excluded.sleep_quality, weight_kg=excluded.weight_kg,
               notes=excluded.notes, updated_at=datetime('now')",
            params![
                log.id, log.date, symptoms_blob,
                log.mood.map(|v| v as i64), log.energy.map(|v| v as i64),
                log.bbt, log.lh_test, log.cervical_mucus,
                log.sexual_activity, log.flow,
                log.sleep_quality.map(|v| v as i64), log.weight_kg,
                log.notes,
            ],
        ).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        Ok(())
    }

    pub fn get_log(&self, date: &str) -> Result<Option<DailyLog>, LunaError> {
        let mut stmt = self.conn
            .prepare("SELECT id, date, symptoms, mood, energy, bbt, lh_test, cervical_mucus, sexual_activity, flow, sleep_quality, weight_kg, notes FROM daily_logs WHERE date = ?1")
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        let mut rows = stmt.query_map(params![date], |row| {
            let symptoms_blob: Vec<u8> = row.get(2)?;
            Ok((row.get(0)?, row.get(1)?, symptoms_blob,
                row.get(3)?, row.get(4)?, row.get(5)?,
                row.get(6)?, row.get(7)?, row.get(8)?,
                row.get(9)?, row.get(10)?, row.get(11)?, row.get(12)?))
        }).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        if let Some(row) = rows.next() {
            type LogRow = (String, String, Vec<u8>,
                Option<i64>, Option<i64>, Option<f64>,
                Option<String>, Option<String>, Option<String>,
                Option<String>, Option<i64>, Option<f64>, Option<String>);
            let (id, date, symptoms_blob, mood, energy, bbt, lh_test,
                 cervical_mucus, sexual_activity, flow, sleep_quality, weight_kg, notes): LogRow
                = row.map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

            let symptoms: Vec<String> = decompress_blob(&symptoms_blob)
                .ok()
                .and_then(|b| serde_json::from_slice(&b).ok())
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
                sleep_quality: sleep_quality.map(|v| v as u8),
                weight_kg,
                notes,
            }))
        } else {
            Ok(None)
        }
    }

    pub fn get_logs_range(&self, from: &str, to: &str) -> Result<Vec<DailyLog>, LunaError> {
        let mut stmt = self.conn
            .prepare("SELECT id, date, symptoms, mood, energy, bbt, lh_test, cervical_mucus, sexual_activity, flow, sleep_quality, weight_kg, notes FROM daily_logs WHERE date BETWEEN ?1 AND ?2 ORDER BY date")
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        let logs = stmt.query_map(params![from, to], |row| {
            let symptoms_blob: Vec<u8> = row.get(2)?;
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?, symptoms_blob,
                row.get::<_, Option<i64>>(3)?, row.get::<_, Option<i64>>(4)?,
                row.get::<_, Option<f64>>(5)?, row.get::<_, Option<String>>(6)?,
                row.get::<_, Option<String>>(7)?, row.get::<_, Option<String>>(8)?,
                row.get::<_, Option<String>>(9)?,
                row.get::<_, Option<i64>>(10)?, row.get::<_, Option<f64>>(11)?,
                row.get::<_, Option<String>>(12)?))
        })
        .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?
        .filter_map(|r| r.ok())
        .map(|(id, date, symptoms_blob, mood, energy, bbt, lh_test,
               cervical_mucus, sexual_activity, flow, sleep_quality, weight_kg, notes)| {
            let symptoms = decompress_blob(&symptoms_blob)
                .ok()
                .and_then(|b| serde_json::from_slice(&b).ok())
                .unwrap_or_default();
            DailyLog { id, date, symptoms, mood: mood.map(|v| v as u8),
                       energy: energy.map(|v| v as u8), bbt, lh_test,
                       cervical_mucus, sexual_activity, flow,
                       sleep_quality: sleep_quality.map(|v| v as u8), weight_kg, notes }
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

    // ─── UserProfile ──────────────────────────────────────────────────────────

    pub fn get_user_profile(&self) -> Result<UserProfile, LunaError> {
        let mut stmt = self.conn
            .prepare("SELECT tracking_mode, contraception, pill_reminder, notif_period, notif_fertile, notif_pill, edd, calm_mode, health_sync FROM user_profile WHERE id = 1")
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        let mut rows = stmt.query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, Option<String>>(2)?,
                row.get::<_, i64>(3)?,
                row.get::<_, i64>(4)?,
                row.get::<_, i64>(5)?,
                row.get::<_, Option<String>>(6)?,
                row.get::<_, i64>(7)?,
                row.get::<_, i64>(8)?,
            ))
        }).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        if let Some(Ok((tm, ct, pill_reminder, np, nf, npill, edd, calm, health))) = rows.next() {
            Ok(UserProfile {
                tracking_mode: TrackingMode::from_str(&tm),
                contraception: ContraceptionType::from_str(&ct),
                pill_reminder_time: pill_reminder,
                notif_period: np != 0,
                notif_fertile: nf != 0,
                notif_pill: npill != 0,
                edd,
                calm_mode: calm != 0,
                health_sync: health != 0,
            })
        } else {
            Ok(UserProfile::default())
        }
    }

    pub fn set_user_profile(&self, profile: &UserProfile) -> Result<(), LunaError> {
        self.conn.execute(
            "INSERT INTO user_profile (id, tracking_mode, contraception, pill_reminder, notif_period, notif_fertile, notif_pill, edd, calm_mode, health_sync, updated_at)
             VALUES (1, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, datetime('now'))
             ON CONFLICT(id) DO UPDATE SET
               tracking_mode=excluded.tracking_mode, contraception=excluded.contraception,
               pill_reminder=excluded.pill_reminder, notif_period=excluded.notif_period,
               notif_fertile=excluded.notif_fertile, notif_pill=excluded.notif_pill,
               edd=excluded.edd, calm_mode=excluded.calm_mode, health_sync=excluded.health_sync,
               updated_at=datetime('now')",
            params![
                profile.tracking_mode.as_str(),
                profile.contraception.as_str(),
                profile.pill_reminder_time,
                profile.notif_period as i64,
                profile.notif_fertile as i64,
                profile.notif_pill as i64,
                profile.edd,
                profile.calm_mode as i64,
                profile.health_sync as i64,
            ],
        ).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        Ok(())
    }

    // ─── PregnancyLog ─────────────────────────────────────────────────────────

    pub fn upsert_pregnancy_log(&self, log: &PregnancyLog) -> Result<(), LunaError> {
        let symptoms_blob = compress_blob(&serde_json::to_vec(&log.symptoms)?)?;
        self.conn.execute(
            "INSERT INTO pregnancy_logs (id, date, hcg_positive, kicks, nausea_level, weight_kg, symptoms, notes, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, datetime('now'))
             ON CONFLICT(date) DO UPDATE SET
               hcg_positive=excluded.hcg_positive, kicks=excluded.kicks,
               nausea_level=excluded.nausea_level, weight_kg=excluded.weight_kg,
               symptoms=excluded.symptoms, notes=excluded.notes, updated_at=datetime('now')",
            params![
                log.id, log.date,
                log.hcg_positive.map(|v| v as i64),
                log.kicks.map(|v| v as i64),
                log.nausea_level.map(|v| v as i64),
                log.weight_kg,
                symptoms_blob,
                log.notes,
            ],
        ).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;
        Ok(())
    }

    pub fn get_pregnancy_log(&self, date: &str) -> Result<Option<PregnancyLog>, LunaError> {
        let mut stmt = self.conn
            .prepare("SELECT id, date, hcg_positive, kicks, nausea_level, weight_kg, symptoms, notes FROM pregnancy_logs WHERE date = ?1")
            .map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        let mut rows = stmt.query_map(params![date], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, Option<i64>>(2)?,
                row.get::<_, Option<i64>>(3)?,
                row.get::<_, Option<i64>>(4)?,
                row.get::<_, Option<f64>>(5)?,
                row.get::<_, Vec<u8>>(6)?,
                row.get::<_, Option<String>>(7)?,
            ))
        }).map_err(|e| LunaError::DatabaseCorrupted(e.to_string()))?;

        if let Some(Ok((id, date, hcg, kicks, nausea, weight, symptoms_blob, notes))) = rows.next() {
            let symptoms: Vec<String> = decompress_blob(&symptoms_blob)
                .ok()
                .and_then(|b| serde_json::from_slice(&b).ok())
                .unwrap_or_default();
            Ok(Some(PregnancyLog {
                id, date,
                hcg_positive: hcg.map(|v| v != 0),
                kicks: kicks.map(|v| v as u8),
                nausea_level: nausea.map(|v| v as u8),
                weight_kg: weight,
                symptoms,
                notes,
            }))
        } else {
            Ok(None)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use secrecy::SecretVec;
    use tempfile::NamedTempFile;

    fn test_db() -> (LunaDb, NamedTempFile) {
        let tmp = NamedTempFile::new().unwrap();
        let key = SecretVec::new(vec![0u8; 32]);
        let db = LunaDb::open(tmp.path().to_str().unwrap(), &key).unwrap();
        (db, tmp)
    }

    #[test]
    fn test_user_profile_default() {
        let (db, _tmp) = test_db();
        let profile = db.get_user_profile().unwrap();
        assert!(matches!(profile.tracking_mode, crate::engine::types::TrackingMode::Regular));
        assert!(!profile.calm_mode);
    }

    #[test]
    fn test_user_profile_roundtrip() {
        let (db, _tmp) = test_db();
        let mut profile = crate::engine::types::UserProfile::default();
        profile.tracking_mode = crate::engine::types::TrackingMode::Ttc;
        profile.contraception = crate::engine::types::ContraceptionType::Pill;
        profile.pill_reminder_time = Some("08:00".to_string());
        profile.notif_period = true;
        profile.calm_mode = true;
        db.set_user_profile(&profile).unwrap();

        let loaded = db.get_user_profile().unwrap();
        assert!(matches!(loaded.tracking_mode, crate::engine::types::TrackingMode::Ttc));
        assert!(matches!(loaded.contraception, crate::engine::types::ContraceptionType::Pill));
        assert_eq!(loaded.pill_reminder_time, Some("08:00".to_string()));
        assert!(loaded.calm_mode);
    }

    #[test]
    fn test_pregnancy_log_roundtrip() {
        let (db, _tmp) = test_db();
        use chrono::NaiveDate;
        let mut log = crate::engine::types::PregnancyLog::new(
            NaiveDate::from_ymd_opt(2026, 3, 15).unwrap()
        );
        log.hcg_positive = Some(true);
        log.kicks = Some(10);
        log.nausea_level = Some(3);
        log.weight_kg = Some(68.5);
        log.symptoms = vec!["nausea".to_string(), "fatigue".to_string()];
        db.upsert_pregnancy_log(&log).unwrap();

        let loaded = db.get_pregnancy_log("2026-03-15").unwrap().unwrap();
        assert_eq!(loaded.hcg_positive, Some(true));
        assert_eq!(loaded.kicks, Some(10));
        assert_eq!(loaded.weight_kg, Some(68.5));
        assert_eq!(loaded.symptoms, vec!["nausea", "fatigue"]);
    }
}
