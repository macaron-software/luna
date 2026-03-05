use crate::engine::types::DailyLog;
use crate::error::LunaError;

/// Exporte les logs dans un format CSV RFC 4180.
/// Colonnes : date,flow,mood,energy,bbt,lh_test,cervical_mucus,sexual_activity,sleep_quality,weight_kg,symptoms,notes
pub fn export_csv(logs: &[DailyLog]) -> Result<String, LunaError> {
    let mut out = String::from(
        "date,flow,mood,energy,bbt,lh_test,cervical_mucus,sexual_activity,sleep_quality,weight_kg,symptoms,notes\r\n"
    );

    for log in logs {
        let symptoms = log.symptoms.join(";");
        let row = format!(
            "{},{},{},{},{},{},{},{},{},{},{},{}\r\n",
            log.date,
            log.flow.as_deref().unwrap_or(""),
            log.mood.map(|v| v.to_string()).unwrap_or_default(),
            log.energy.map(|v| v.to_string()).unwrap_or_default(),
            log.bbt.map(|v| format!("{:.2}", v)).unwrap_or_default(),
            log.lh_test.as_deref().unwrap_or(""),
            log.cervical_mucus.as_deref().unwrap_or(""),
            log.sexual_activity.as_deref().unwrap_or(""),
            log.sleep_quality.map(|v| v.to_string()).unwrap_or_default(),
            log.weight_kg.map(|v| format!("{:.1}", v)).unwrap_or_default(),
            csv_escape(&symptoms),
            csv_escape(log.notes.as_deref().unwrap_or("")),
        );
        out.push_str(&row);
    }

    Ok(out)
}

/// Échappe une valeur CSV : entoure de guillemets si contient virgule/guillemet/newline.
fn csv_escape(s: &str) -> String {
    if s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r') {
        format!("\"{}\"", s.replace('"', "\"\""))
    } else {
        s.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::engine::types::DailyLog;
    use chrono::NaiveDate;

    fn make_log(date: &str) -> DailyLog {
        let mut log = DailyLog::new(date.parse::<NaiveDate>().unwrap());
        log.flow = Some("medium".into());
        log.mood = Some(3);
        log.bbt = Some(36.7);
        log.symptoms = vec!["cramps".into(), "fatigue".into()];
        log.notes = Some("test, avec virgule".into());
        log
    }

    #[test]
    fn test_export_csv_header() {
        let csv = export_csv(&[]).unwrap();
        assert!(csv.starts_with("date,flow,"));
    }

    #[test]
    fn test_export_csv_one_row() {
        let log = make_log("2026-01-15");
        let csv = export_csv(&[log]).unwrap();
        assert!(csv.contains("2026-01-15"));
        assert!(csv.contains("medium"));
        assert!(csv.contains("36.70"));
        assert!(csv.contains("\"test, avec virgule\""));
    }

    #[test]
    fn test_export_csv_symptoms_semicolon() {
        let log = make_log("2026-02-01");
        let csv = export_csv(&[log]).unwrap();
        assert!(csv.contains("cramps;fatigue"));
    }

    #[test]
    fn test_csv_escape_no_special() {
        assert_eq!(csv_escape("hello"), "hello");
    }

    #[test]
    fn test_csv_escape_with_comma() {
        assert_eq!(csv_escape("a,b"), "\"a,b\"");
    }

    #[test]
    fn test_csv_escape_with_quote() {
        assert_eq!(csv_escape("say \"hi\""), "\"say \"\"hi\"\"\"");
    }
}
