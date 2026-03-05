use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ─── Cycle ───────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct Cycle {
    pub id: String,
    /// ISO-8601 : "2026-01-15"
    pub start_date: String,
    /// None si cycle en cours
    pub end_date: Option<String>,
    /// Durée des règles en jours
    pub period_length: Option<u8>,
    pub notes: Option<String>,
}

impl Cycle {
    pub fn new(start_date: NaiveDate) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            start_date: start_date.to_string(),
            end_date: None,
            period_length: None,
            notes: None,
        }
    }

    pub fn start(&self) -> Option<NaiveDate> {
        self.start_date.parse().ok()
    }

    pub fn end(&self) -> Option<NaiveDate> {
        self.end_date.as_deref().and_then(|s| s.parse().ok())
    }

    /// Durée totale du cycle (start → prochain start) en jours
    pub fn cycle_length(&self, next_start: Option<NaiveDate>) -> Option<i64> {
        let start = self.start()?;
        let next = next_start?;
        Some((next - start).num_days())
    }
}

// ─── DailyLog ────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct DailyLog {
    pub id: String,
    /// ISO-8601
    pub date: String,
    pub symptoms: Vec<String>,
    /// 1 (très mauvaise) à 5 (excellente)
    pub mood: Option<u8>,
    /// 1 (épuisée) à 5 (pleine d'énergie)
    pub energy: Option<u8>,
    /// Température basale en °C, ex: 36.7
    pub bbt: Option<f64>,
    /// "negative" | "positive" | "peak"
    pub lh_test: Option<String>,
    /// "dry" | "sticky" | "creamy" | "watery" | "egg_white"
    pub cervical_mucus: Option<String>,
    /// "none" | "protected" | "unprotected"
    pub sexual_activity: Option<String>,
    /// Flux menstruel : "none" | "spotting" | "light" | "medium" | "heavy"
    pub flow: Option<String>,
    /// Qualité du sommeil : 1 (très mauvaise) à 5 (excellente)
    pub sleep_quality: Option<u8>,
    /// Poids en kg, ex: 62.5
    pub weight_kg: Option<f64>,
    pub notes: Option<String>,
}

impl DailyLog {
    pub fn new(date: NaiveDate) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            date: date.to_string(),
            symptoms: vec![],
            mood: None,
            energy: None,
            bbt: None,
            lh_test: None,
            cervical_mucus: None,
            sexual_activity: None,
            flow: None,
            sleep_quality: None,
            weight_kg: None,
            notes: None,
        }
    }

    pub fn date(&self) -> Option<NaiveDate> {
        self.date.parse().ok()
    }

    pub fn has_period(&self) -> bool {
        matches!(
            self.flow.as_deref(),
            Some("spotting") | Some("light") | Some("medium") | Some("heavy")
        )
    }
}

// ─── Prediction ──────────────────────────────────────────────────────────────

#[derive(Debug, Clone, uniffi::Record)]
pub struct Prediction {
    /// ISO-8601 : date prédite de début des prochaines règles
    pub next_period_start: String,
    /// Intervalle de confiance en jours (±)
    pub confidence_days: u8,
    /// Premier jour de la fenêtre fertile
    pub fertile_window_start: String,
    /// Dernier jour de la fenêtre fertile
    pub fertile_window_end: String,
    /// Jour d'ovulation estimé (peut être None si pas assez de données)
    pub ovulation_day: Option<String>,
    /// "calendar" | "bbt" | "lh" | "combined"
    pub algorithm: String,
    /// 0–100 : niveau de confiance de la prédiction
    pub confidence_score: u8,
}

// ─── CycleSummary ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, uniffi::Record)]
pub struct CycleSummary {
    pub total_cycles: u32,
    pub average_cycle_length: f64,
    pub average_period_length: f64,
    pub min_cycle_length: u32,
    pub max_cycle_length: u32,
    /// Écart-type de la durée des cycles
    pub cycle_std_dev: f64,
    /// "regular" | "slightly_irregular" | "irregular"
    pub regularity: String,
}

// ─── TrackingMode ────────────────────────────────────────────────────────────

/// Mode de suivi de la santé reproductive
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, uniffi::Enum)]
pub enum TrackingMode {
    Regular,
    Ttc,
    Pregnant,
    Postpartum,
    Perimenopause,
}

impl Default for TrackingMode {
    fn default() -> Self { TrackingMode::Regular }
}

impl TrackingMode {
    pub fn as_str(&self) -> &'static str {
        match self {
            TrackingMode::Regular       => "regular",
            TrackingMode::Ttc           => "ttc",
            TrackingMode::Pregnant      => "pregnant",
            TrackingMode::Postpartum    => "postpartum",
            TrackingMode::Perimenopause => "perimenopause",
        }
    }
    pub fn from_str(s: &str) -> Self {
        match s {
            "ttc"           => TrackingMode::Ttc,
            "pregnant"      => TrackingMode::Pregnant,
            "postpartum"    => TrackingMode::Postpartum,
            "perimenopause" => TrackingMode::Perimenopause,
            _               => TrackingMode::Regular,
        }
    }
}

// ─── ContraceptionType ───────────────────────────────────────────────────────

/// Type de contraception
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, uniffi::Enum)]
pub enum ContraceptionType {
    None,
    Pill,
    Patch,
    Ring,
    Injection,
    Iud,
    Implant,
    Condom,
    Other,
}

impl Default for ContraceptionType {
    fn default() -> Self { ContraceptionType::None }
}

impl ContraceptionType {
    pub fn as_str(&self) -> &'static str {
        match self {
            ContraceptionType::None      => "none",
            ContraceptionType::Pill      => "pill",
            ContraceptionType::Patch     => "patch",
            ContraceptionType::Ring      => "ring",
            ContraceptionType::Injection => "injection",
            ContraceptionType::Iud       => "iud",
            ContraceptionType::Implant   => "implant",
            ContraceptionType::Condom    => "condom",
            ContraceptionType::Other     => "other",
        }
    }
    pub fn from_str(s: &str) -> Self {
        match s {
            "pill"      => ContraceptionType::Pill,
            "patch"     => ContraceptionType::Patch,
            "ring"      => ContraceptionType::Ring,
            "injection" => ContraceptionType::Injection,
            "iud"       => ContraceptionType::Iud,
            "implant"   => ContraceptionType::Implant,
            "condom"    => ContraceptionType::Condom,
            "other"     => ContraceptionType::Other,
            _           => ContraceptionType::None,
        }
    }
}

// ─── UserProfile ─────────────────────────────────────────────────────────────

/// Profil utilisateur — préférences et mode de suivi
#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct UserProfile {
    pub tracking_mode: TrackingMode,
    pub contraception: ContraceptionType,
    pub pill_reminder_time: Option<String>,
    pub notif_period: bool,
    pub notif_fertile: bool,
    pub notif_pill: bool,
    pub edd: Option<String>,
    pub calm_mode: bool,
    pub health_sync: bool,
}

impl Default for UserProfile {
    fn default() -> Self {
        Self {
            tracking_mode: TrackingMode::Regular,
            contraception: ContraceptionType::None,
            pill_reminder_time: None,
            notif_period: true,
            notif_fertile: false,
            notif_pill: false,
            edd: None,
            calm_mode: false,
            health_sync: false,
        }
    }
}

// ─── PregnancyLog ─────────────────────────────────────────────────────────────

/// Log de grossesse — données quotidiennes spécifiques à la grossesse
#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct PregnancyLog {
    pub id: String,
    pub date: String,
    pub hcg_positive: Option<bool>,
    pub kicks: Option<u8>,
    pub nausea_level: Option<u8>,
    pub weight_kg: Option<f64>,
    pub symptoms: Vec<String>,
    pub notes: Option<String>,
}

impl PregnancyLog {
    pub fn new(date: NaiveDate) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            date: date.to_string(),
            hcg_positive: None,
            kicks: None,
            nausea_level: None,
            weight_kg: None,
            symptoms: vec![],
            notes: None,
        }
    }
}

// ─── Symptom catalogue ───────────────────────────────────────────────────────

/// Identifiants des symptômes — correspondance avec clés i18n
pub mod symptoms {
    // Phase menstruelle
    pub const CRAMPS: &str = "cramps";
    pub const FLOW_LIGHT: &str = "flow_light";
    pub const FLOW_MEDIUM: &str = "flow_medium";
    pub const FLOW_HEAVY: &str = "flow_heavy";
    pub const CLOTS: &str = "clots";
    pub const LOWER_BACK_PAIN: &str = "lower_back_pain";
    pub const BLOATING: &str = "bloating";
    pub const NAUSEA: &str = "nausea";
    pub const HEADACHE: &str = "headache";
    pub const FATIGUE: &str = "fatigue";
    pub const DIARRHEA: &str = "diarrhea";

    // Phase lutéale / SPM
    pub const BREAST_TENDERNESS: &str = "breast_tenderness";
    pub const BREAST_SWELLING: &str = "breast_swelling";
    pub const WATER_RETENTION: &str = "water_retention";
    pub const ACNE: &str = "acne";
    pub const IRRITABILITY: &str = "irritability";
    pub const ANXIETY: &str = "anxiety";
    pub const LOW_MOOD: &str = "low_mood";
    pub const FOOD_CRAVINGS_SWEET: &str = "cravings_sweet";
    pub const FOOD_CRAVINGS_SALTY: &str = "cravings_salty";
    pub const INSOMNIA: &str = "insomnia";
    pub const MIGRAINE: &str = "migraine";
    pub const CONSTIPATION: &str = "constipation";
    pub const LOW_LIBIDO: &str = "low_libido";

    // Phase ovulatoire
    pub const HIGH_LIBIDO: &str = "high_libido";
    pub const MITTELSCHMERZ: &str = "mittelschmerz";
    pub const LIGHT_SPOTTING: &str = "light_spotting";
    pub const HIGH_ENERGY: &str = "high_energy";

    // Phase folliculaire
    pub const GLOWING_SKIN: &str = "glowing_skin";
    pub const MOTIVATION: &str = "motivation";

    // Général
    pub const DIZZINESS: &str = "dizziness";
    pub const FEVER: &str = "fever";
    pub const COLD: &str = "cold";
    pub const HIGH_STRESS: &str = "high_stress";
    pub const POOR_SLEEP: &str = "poor_sleep";
    pub const INTENSE_EXERCISE: &str = "intense_exercise";
    pub const TRAVEL: &str = "travel";

    // Péri-ménopause
    pub const HOT_FLASH: &str = "hot_flash";
    pub const NIGHT_SWEATS: &str = "night_sweats";
    pub const VAGINAL_DRYNESS: &str = "vaginal_dryness";
}
