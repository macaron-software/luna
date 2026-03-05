use chrono::NaiveDate;

use crate::engine::types::{Cycle, DailyLog, Prediction};

/// Moteur de prédiction du cycle — 100% on-device, aucun appel réseau.
///
/// Implémentation :
///   v1 — moyenne mobile pondérée (calendrier)
///   v2 — ajustement BBT si données disponibles  [TODO Phase 2]
///   v3 — ajustement LH                          [TODO Phase 2]
pub struct PredictionEngine;

impl PredictionEngine {
    /// Calcule la prochaine prédiction à partir des cycles historiques + logs.
    pub fn predict(cycles: &[Cycle], logs: &[DailyLog]) -> Prediction {
        let cycle_lengths = Self::compute_cycle_lengths(cycles);
        let period_lengths = Self::compute_period_lengths(cycles, logs);

        let (avg_cycle, std_dev, confidence) = Self::weighted_average(&cycle_lengths);
        let _avg_period = Self::simple_average(&period_lengths).unwrap_or(5.0);

        // Date de début du cycle le plus récent
        let last_start = cycles
            .iter()
            .filter_map(|c| c.start())
            .max()
            .unwrap_or_else(|| chrono::Local::now().date_naive());

        let next_start = last_start + chrono::Duration::days(avg_cycle.round() as i64);
        let confidence_days = (std_dev.ceil() as u8).clamp(1, 7);

        // Fenêtre fertile = ovulation estimée ± 5j avant et 1j après
        // Ovulation ≈ J(avg_cycle - 14) depuis dernier début
        let luteal_phase = 14i64;
        let ovulation_offset = (avg_cycle.round() as i64) - luteal_phase;
        let ovulation_day = last_start + chrono::Duration::days(ovulation_offset);
        let fertile_start = ovulation_day - chrono::Duration::days(5);
        let fertile_end = ovulation_day + chrono::Duration::days(1);

        // Étiquette sémantique selon la variabilité mesurée
        let algorithm = if cycle_lengths.len() < 3 {
            "calendar_low_data"
        } else if std_dev >= 7.0 {
            // Cycles très irréguliers (std_dev ≥ 7j) : on prévient l'UI
            "calendar_irregular"
        } else {
            "calendar"
        };

        Prediction {
            next_period_start: next_start.to_string(),
            confidence_days,
            fertile_window_start: fertile_start.to_string(),
            fertile_window_end: fertile_end.to_string(),
            ovulation_day: Some(ovulation_day.to_string()),
            algorithm: algorithm.to_string(),
            confidence_score: confidence,
        }
    }

    /// Durée de chaque cycle (en jours) entre deux débuts consécutifs.
    fn compute_cycle_lengths(cycles: &[Cycle]) -> Vec<f64> {
        let mut starts: Vec<NaiveDate> = cycles.iter().filter_map(|c| c.start()).collect();
        starts.sort();

        starts
            .windows(2)
            .map(|w| (w[1] - w[0]).num_days() as f64)
            // Filtrer les valeurs aberrantes (< 15j ou > 60j)
        .filter(|&d| (15.0..=60.0).contains(&d))
            .collect()
    }

    /// Durée des règles pour chaque cycle.
    fn compute_period_lengths(cycles: &[Cycle], logs: &[DailyLog]) -> Vec<f64> {
        cycles
            .iter()
            .filter_map(|c| {
                let start = c.start()?;
                // Compte les jours avec flux depuis le début du cycle
                let count = logs
                    .iter()
                    .filter(|l| {
                        if let Some(d) = l.date() {
                            let diff = (d - start).num_days();
                            (0..=14).contains(&diff) && l.has_period()
                        } else {
                            false
                        }
                    })
                    .count() as f64;
                if count > 0.0 {
                    Some(count)
                } else {
                    c.period_length.map(|p| p as f64)
                }
            })
            .filter(|&d| (1.0..=14.0).contains(&d))
            .collect()
    }

    /// Moyenne pondérée exponentielle (cycles récents = poids plus élevé).
    /// Retourne (moyenne, écart-type, score_confiance 0-100).
    fn weighted_average(values: &[f64]) -> (f64, f64, u8) {
        if values.is_empty() {
            return (28.0, 3.0, 30); // Défaut scientifique si aucune donnée
        }
        if values.len() == 1 {
            return (values[0], 3.0, 50);
        }

        // Poids exponentiels : le plus récent a le poids le plus élevé
        let n = values.len();
        let decay = 0.8_f64;
        let weights: Vec<f64> = (0..n)
            .map(|i| decay.powi((n - 1 - i) as i32))
            .collect();
        let total_weight: f64 = weights.iter().sum();

        let mean: f64 = values
            .iter()
            .zip(weights.iter())
            .map(|(v, w)| v * w)
            .sum::<f64>()
            / total_weight;

        // Variance pondérée
        let variance: f64 = values
            .iter()
            .zip(weights.iter())
            .map(|(v, w)| w * (v - mean).powi(2))
            .sum::<f64>()
            / total_weight;
        let std_dev = variance.sqrt();

        // Score de confiance : plus de cycles + faible écart-type = confiance élevée
        let n_score = ((n as f64 / 6.0) * 40.0).min(40.0) as u8; // max 40 pts pour 6+ cycles
        let stability_score = ((1.0 - (std_dev / 7.0)).max(0.0) * 60.0) as u8; // max 60 pts
        let confidence = n_score + stability_score;

        (mean, std_dev, confidence.min(100))
    }

    fn simple_average(values: &[f64]) -> Option<f64> {
        if values.is_empty() {
            return None;
        }
        Some(values.iter().sum::<f64>() / values.len() as f64)
    }

    /// Détermine la phase du cycle pour une date donnée.
    /// `period_length_days` : durée réelle des règles (None → valeur par défaut 5j).
    pub fn phase_for_date(
        date: NaiveDate,
        last_period_start: NaiveDate,
        avg_cycle_length: f64,
        period_length_days: Option<u8>,
    ) -> CyclePhase {
        let day_of_cycle = (date - last_period_start).num_days();
        if day_of_cycle < 0 {
            return CyclePhase::Unknown;
        }

        let period_days = period_length_days.unwrap_or(5) as i64;
        let cycle_len = avg_cycle_length.round() as i64;
        let ovulation = cycle_len - 14;

        match day_of_cycle {
            d if d < period_days => CyclePhase::Menstrual,
            d if d <= ovulation - 2 => CyclePhase::Follicular,
            d if d <= ovulation + 1 => CyclePhase::Ovulatory,
            d if d < cycle_len => CyclePhase::Luteal,
            _ => CyclePhase::Unknown,
        }
    }
}

#[derive(Debug, Clone, PartialEq, uniffi::Enum)]
pub enum CyclePhase {
    Menstrual,
    Follicular,
    Ovulatory,
    Luteal,
    Unknown,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_predict_with_regular_cycles() {
        let cycles: Vec<Cycle> = vec!["2025-09-01", "2025-09-29", "2025-10-27", "2025-11-24"]
            .into_iter()
            .map(|d| Cycle::new(d.parse().unwrap()))
            .collect();

        let pred = PredictionEngine::predict(&cycles, &[]);
        let next: NaiveDate = pred.next_period_start.parse().unwrap();
        let expected: NaiveDate = "2025-12-22".parse().unwrap();

        // Tolérance ±2 jours pour un cycle régulier de 28j
        let diff = (next - expected).num_days().abs();
        assert!(diff <= 2, "Prédiction trop éloignée : diff={diff}j");
        assert!(pred.confidence_score >= 60, "Confiance trop faible pour cycle régulier");
    }

    #[test]
    fn test_predict_with_no_data() {
        let pred = PredictionEngine::predict(&[], &[]);
        assert_eq!(pred.algorithm, "calendar_low_data");
        assert_eq!(pred.confidence_score, 30);
    }

    #[test]
    fn test_phase_detection() {
        let start: NaiveDate = "2026-01-01".parse().unwrap();
        assert_eq!(
            PredictionEngine::phase_for_date("2026-01-02".parse().unwrap(), start, 28.0, None),
            CyclePhase::Menstrual
        );
        assert_eq!(
            PredictionEngine::phase_for_date("2026-01-15".parse().unwrap(), start, 28.0, None),
            CyclePhase::Ovulatory
        );
        assert_eq!(
            PredictionEngine::phase_for_date("2026-01-20".parse().unwrap(), start, 28.0, None),
            CyclePhase::Luteal
        );
    }

    #[test]
    fn test_confidence_increases_with_more_cycles() {
        let few: Vec<Cycle> = vec!["2026-01-01", "2026-01-29"]
            .into_iter()
            .map(|d| Cycle::new(d.parse().unwrap()))
            .collect();
        let many: Vec<Cycle> = vec![
            "2025-07-01", "2025-07-29", "2025-08-26", "2025-09-23",
            "2025-10-21", "2025-11-18", "2025-12-16",
        ]
        .into_iter()
        .map(|d| Cycle::new(d.parse().unwrap()))
        .collect();

        let p_few = PredictionEngine::predict(&few, &[]);
        let p_many = PredictionEngine::predict(&many, &[]);
        assert!(
            p_many.confidence_score > p_few.confidence_score,
            "Plus de cycles devrait donner plus de confiance"
        );
    }

    // ─── Edge cases : cycles très irréguliers ────────────────────────────────
    //
    // Données réelles observées (Twitter/X, mars 2026) :
    //   16j, 50j, 16j, 18j (printemps-été 2025) puis 44j, 28j, 16j (hiver-printemps 2026)
    // Règles : 6 à 10 jours — profil oligoménorrhée/polyménorrhée alternant.

    /// Cycles fortement irréguliers (16-50j) → algorithme "calendar_irregular",
    /// confiance faible, mais prédiction dans une fourchette raisonnable.
    #[test]
    fn test_highly_irregular_cycles_real_data() {
        // Reconstitution depuis les screenshots : débuts consécutifs
        // Longueurs: 16, 50, 16, 18, 44, 28 → std_dev ≈ 12.5j
        let starts = [
            "2025-01-01", "2025-01-17", "2025-03-08",
            "2025-03-24", "2025-04-11", "2025-05-25", "2025-06-22",
        ];
        let cycles: Vec<Cycle> = starts.iter()
            .map(|d| Cycle::new(d.parse().unwrap()))
            .collect();

        let pred = PredictionEngine::predict(&cycles, &[]);

        assert_eq!(pred.algorithm, "calendar_irregular",
            "Cycle irrégulier (std_dev≈12.5j) doit être étiqueté calendar_irregular");
        assert!(pred.confidence_score < 50,
            "Confiance doit être faible pour cycles très irréguliers, got {}", pred.confidence_score);

        // La prédiction doit rester dans une plage sensée (15–60j depuis le dernier début)
        let last: NaiveDate = "2025-06-22".parse().unwrap();
        let next: NaiveDate = pred.next_period_start.parse().unwrap();
        let delta = (next - last).num_days();
        assert!((15..=60).contains(&delta),
            "Prédiction hors plage valide : {delta}j depuis le dernier début");
    }

    /// Cycle court de 16 jours : polyménorrhée — doit passer le filtre (≥ 15j).
    #[test]
    fn test_short_cycle_16_days_not_filtered() {
        let cycles: Vec<Cycle> = vec!["2026-01-01", "2026-01-17", "2026-02-02", "2026-02-18"]
            .into_iter()
            .map(|d| Cycle::new(d.parse().unwrap()))
            .collect();

        let pred = PredictionEngine::predict(&cycles, &[]);
        let last: NaiveDate = "2026-02-18".parse().unwrap();
        let next: NaiveDate = pred.next_period_start.parse().unwrap();
        let delta = (next - last).num_days();

        assert!((14..=20).contains(&delta),
            "Prédiction doit être proche de 16j pour cycle court, got {delta}j");
    }

    /// Cycle long de 50 jours : oligoménorrhée — doit passer le filtre (≤ 60j).
    #[test]
    fn test_long_cycle_50_days_not_filtered() {
        let cycles: Vec<Cycle> = vec!["2025-01-01", "2025-02-20", "2025-04-11", "2025-06-01"]
            .into_iter()
            .map(|d| Cycle::new(d.parse().unwrap()))
            .collect();

        let pred = PredictionEngine::predict(&cycles, &[]);
        let last: NaiveDate = "2025-06-01".parse().unwrap();
        let next: NaiveDate = pred.next_period_start.parse().unwrap();
        let delta = (next - last).num_days();

        assert!((45..=55).contains(&delta),
            "Prédiction doit être proche de 50j pour cycle long, got {delta}j");
    }

    /// Alternance court/long (16j, 50j, 16j) : volatilité max → calendar_irregular.
    #[test]
    fn test_alternating_short_long_cycles() {
        let cycles: Vec<Cycle> = vec![
            "2025-04-05", "2025-04-21", "2025-06-10",
            "2025-06-26", "2026-01-07", "2026-02-20", "2026-03-20",
        ]
        .into_iter()
        .map(|d| Cycle::new(d.parse().unwrap()))
        .collect();

        // cycle_lengths entre débuts consécutifs: 16, 50, 16, ... 44, 28, 28
        // (le long gap janv est filtré car 195j > 60j)
        let pred = PredictionEngine::predict(&cycles, &[]);
        // Avec le gap filtré, on obtient cycles courts/moyens → std_dev élevé
        assert!(pred.confidence_score <= 60,
            "Alternance court/long doit avoir une confiance ≤60, got {}", pred.confidence_score);
    }

    /// Règles de 9-10 jours : phase menstruelle doit couvrir les jours réels.
    #[test]
    fn test_phase_detection_with_long_period_9_days() {
        let start: NaiveDate = "2026-01-01".parse().unwrap();

        // Jour 8 avec règles de 9j → encore en phase menstruelle
        assert_eq!(
            PredictionEngine::phase_for_date(
                "2026-01-09".parse().unwrap(), start, 28.0, Some(9)
            ),
            CyclePhase::Menstrual,
            "Jour 8 avec règles de 9j doit être Menstrual"
        );

        // Jour 10 avec règles de 9j → phase folliculaire
        assert_eq!(
            PredictionEngine::phase_for_date(
                "2026-01-11".parse().unwrap(), start, 28.0, Some(9)
            ),
            CyclePhase::Follicular,
            "Jour 10 avec règles de 9j doit être Follicular"
        );

        // Sans paramètre (défaut 5j) : jour 8 → Follicular (ancien comportement préservé)
        assert_eq!(
            PredictionEngine::phase_for_date(
                "2026-01-09".parse().unwrap(), start, 28.0, None
            ),
            CyclePhase::Follicular,
            "Jour 8 sans period_length (défaut 5j) doit être Follicular"
        );
    }

    /// Règles de 10 jours dans un cycle court de 16j : tout le cycle presque en menstruel.
    #[test]
    fn test_phase_detection_10_day_period_in_16_day_cycle() {
        let start: NaiveDate = "2026-01-01".parse().unwrap();

        // Jour 9 → Menstrual (encore dans les règles)
        assert_eq!(
            PredictionEngine::phase_for_date(
                "2026-01-10".parse().unwrap(), start, 16.0, Some(10)
            ),
            CyclePhase::Menstrual
        );

        // Jour 11 → Follicular (ovulation ≈ J2, donc on est en Luteal)
        // Avec cycle 16j : ovulation = 16-14 = 2, donc tout ≥ J3 est Luteal
        let phase = PredictionEngine::phase_for_date(
            "2026-01-12".parse().unwrap(), start, 16.0, Some(10)
        );
        assert!(
            phase == CyclePhase::Follicular || phase == CyclePhase::Luteal || phase == CyclePhase::Ovulatory,
            "Jour 11 d'un cycle 16j doit être Follicular/Ovulatory/Luteal, got {phase:?}"
        );
    }

    /// Cycle unique de 60 jours (limite haute du filtre) : doit être inclus.
    #[test]
    fn test_boundary_cycle_60_days_included() {
        let cycles: Vec<Cycle> = vec!["2025-01-01", "2025-03-02", "2025-05-01"]
            .into_iter()
            .map(|d| Cycle::new(d.parse().unwrap()))
            .collect();
        // starts: Jan 1, Mar 2 (+60j), May 1 (+60j) → longueurs [60, 60]
        let pred = PredictionEngine::predict(&cycles, &[]);
        let last: NaiveDate = "2025-05-01".parse().unwrap();
        let next: NaiveDate = pred.next_period_start.parse().unwrap();
        let delta = (next - last).num_days();
        assert!((58..=62).contains(&delta), "Cycle 60j doit être inclus, delta={delta}j");
    }

    /// Cycle de 61 jours (hors limites) : doit être FILTRÉ → fallback sur valeur par défaut.
    #[test]
    fn test_boundary_cycle_61_days_filtered() {
        // Un seul intervalle de 61j → filtré → no data → défaut 28j
        let cycles: Vec<Cycle> = vec!["2025-01-01", "2025-03-03"]
            .into_iter()
            .map(|d| Cycle::new(d.parse().unwrap()))
            .collect();
        let pred = PredictionEngine::predict(&cycles, &[]);
        // Avec 1 cycle (61j) filtré → 0 valeurs → weighted_average retourne (28.0, 3.0, 30)
        assert_eq!(pred.algorithm, "calendar_low_data",
            "Cycle filtré doit donner calendar_low_data");
    }

    /// Cycle de 14 jours (hors limites basse) : doit être FILTRÉ.
    #[test]
    fn test_boundary_cycle_14_days_filtered() {
        let cycles: Vec<Cycle> = vec!["2026-01-01", "2026-01-15", "2026-01-29"]
            .into_iter()
            .map(|d| Cycle::new(d.parse().unwrap()))
            .collect();
        // Intervalles : 14j, 14j → tous filtrés (< 15)
        let pred = PredictionEngine::predict(&cycles, &[]);
        assert_eq!(pred.algorithm, "calendar_low_data",
            "Cycles < 15j doivent être filtrés → calendar_low_data");
    }

    /// Phase "inconnue" pour une date avant le début du cycle.
    #[test]
    fn test_phase_unknown_before_cycle_start() {
        let start: NaiveDate = "2026-06-01".parse().unwrap();
        let before: NaiveDate = "2026-05-28".parse().unwrap();
        assert_eq!(
            PredictionEngine::phase_for_date(before, start, 28.0, None),
            CyclePhase::Unknown
        );
    }
}
