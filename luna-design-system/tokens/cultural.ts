/**
 * LUNA Design System — Cultural Diversity Token Layer
 * ============================================================
 * This file documents culture-specific design decisions backed by
 * peer-reviewed research. Rules are applied at runtime by reading
 * the device locale and overriding the default token values.
 *
 * OVERVIEW OF CULTURAL DIMENSIONS IN HEALTH UI (science):
 *
 *   1. COLOR MEANING — varies significantly by culture
 *      Hupka R.B. et al. "Colors: Emotions and Cross-Cultural Associations"
 *      Cross-Cultural Research, 31(2), 171-189, 1997.
 *
 *   2. INFORMATION DENSITY — varies by culture
 *      Hall E.T. "Beyond Culture" 1976. Low-context cultures (DE, NL, NO)
 *      prefer explicit, sparse information. High-context cultures (JP, ZH, KR)
 *      prefer dense information environments.
 *
 *   3. RTL LAYOUT — mirror all directional elements
 *      Arabic/Hebrew users expect UI to be mirrored: navigation arrows reverse,
 *      padding sides swap, text alignment is right. Do NOT just flip text direction;
 *      the entire spatial logic must be mirrored.
 *      — W3C i18n "Structural markup and right-to-left text in HTML." 2023.
 *
 *   4. MENSTRUAL HEALTH VOCABULARY — cultural taboo levels differ
 *      Chrisler J.C. "Leaking, Oozing, Flooding, Dripping."
 *      Feminism & Psychology, 2011.
 *      — In JP context: "seiri" (生理) is clinical and less loaded.
 *      — In AR context: "dawra al-shahriyya" (الدورة الشهرية) = monthly cycle.
 *      — In IN (HI): "mahvari" is common spoken term, "masik dharm" more clinical.
 *      — Avoid "bleeding" in all non-medical UI strings.
 *
 *   5. NUMERICAL FORMAT — critical for cycle tracking dates
 *      — Most locales: day-first (DD/MM/YYYY)
 *      — US: MM/DD/YYYY
 *      — ISO/JP/ZH/KR: YYYY-MM-DD
 *      Use Intl.DateTimeFormat or NSDateFormatter — never hardcode separators.
 *
 *   6. CALENDAR WEEK START — varies (not just cultural, legal in some countries)
 *      — ISO 8601: Monday (EU, most of world)
 *      — US, CA, MX, JP: Sunday
 *      — SA (Arabic): Saturday
 *      Source: Unicode CLDR "weekData" supplemental data.
 *
 *   7. BODY IMAGE AND WEIGHT DISPLAY
 *      Do NOT display BMI prominently. BMI is a poor health metric (Flegal et al.,
 *      JAMA 2013) and weight display can trigger disordered eating (Tylka et al.,
 *      Body Image 2014). LUNA never prominently shows weight; it's an optional
 *      personal log field only.
 *
 * ============================================================
 */

// ---------------------------------------------------------------------------
// LOCALE RULE TABLE
// Each entry describes what LUNA changes for that locale/region group.
// ---------------------------------------------------------------------------

export interface CulturalRule {
  /** ISO 639-1 locale codes this rule applies to */
  locales: string[];
  /** Short label for debugging / docs */
  label: string;
  /** Scientific / UX source */
  source: string;
  /** Token overrides or behavioral flags */
  rules: CulturalTokenOverride;
}

export interface CulturalTokenOverride {
  /** Mirror entire layout (RTL) */
  rtl?: boolean;
  /** Avoid rose/red as error/danger color (use plum or amber instead) */
  avoidRedAsDanger?: boolean;
  /** White as primary background may evoke mourning — use neutral-50 */
  avoidPureWhiteBackground?: boolean;
  /** Compact information density (reduce spacing by 20%) */
  highDensityLayout?: boolean;
  /** Extend line-height for script that needs vertical space */
  extendedLineHeight?: number;
  /** Calendar first day of week: 0=Sun, 1=Mon, 6=Sat */
  calendarFirstDay?: 0 | 1 | 6;
  /** Date format pattern hint (informational — use platform Intl) */
  dateFormatHint?: string;
  /** Vocabulary: clinical vs colloquial preference */
  preferClinicalTerminology?: boolean;
  /** Green overrides: in some ZH contexts green=infidelity; swap to sage-400 */
  avoidGreenForRelationshipContext?: boolean;
}

export const culturalRules: CulturalRule[] = [
  // -------------------------------------------------------------------------
  // RTL LOCALES — Arabic, Hebrew, Persian, Urdu
  // -------------------------------------------------------------------------
  {
    locales: ["ar", "ar-SA", "ar-EG", "ar-MA", "ar-DZ", "ar-AE"],
    label: "Arabic (RTL)",
    source:
      "W3C i18n Arabic Layout Requirements 2022; Unicode BiDi Algorithm UAX#9; " +
      "Chrisler 2011 (terminology). Arabic calendar first day = Saturday (Saudi ISO).",
    rules: {
      rtl: true,
      avoidPureWhiteBackground: false, // white = purity/cleanliness in Arabic culture
      calendarFirstDay: 6,             // Saudi Arabia: Saturday; adjust per sub-locale
      dateFormatHint: "DD/MM/YYYY",
      preferClinicalTerminology: false, // colloquial "dawra" preferred in UI
    },
  },
  {
    locales: ["he", "he-IL"],
    label: "Hebrew (RTL)",
    source:
      "W3C i18n Hebrew Layout Requirements; Unicode BiDi UAX#9. " +
      "Israeli calendar week starts Sunday.",
    rules: {
      rtl: true,
      calendarFirstDay: 0,             // Sunday in Israel
      dateFormatHint: "DD/MM/YYYY",
    },
  },
  {
    locales: ["fa", "fa-IR"],
    label: "Persian / Farsi (RTL)",
    source:
      "W3C i18n Arabic Layout Requirements (applies to Perso-Arabic script). " +
      "Persian calendar = Solar Hijri (Jalali) — LUNA shows Gregorian + local.",
    rules: {
      rtl: true,
      calendarFirstDay: 6,             // Iran week starts Saturday
      dateFormatHint: "YYYY/MM/DD",
      preferClinicalTerminology: true,
    },
  },

  // -------------------------------------------------------------------------
  // EAST ASIAN — Japanese, Chinese, Korean
  // Red = luck; white = mourning; high information density
  // -------------------------------------------------------------------------
  {
    locales: ["ja", "ja-JP"],
    label: "Japanese",
    source:
      "Hupka et al. 1997 (red=joy/luck); Ou et al. 2004 (white=mourning in JP); " +
      "Nagata et al. 2004 (UI density preference); Apple HIG Japanese localization; " +
      "JISX0208 (CJK character spacing — do not override).",
    rules: {
      avoidRedAsDanger: true,
      avoidPureWhiteBackground: true,  // white = mourning in JP → use neutral-50
      highDensityLayout: true,
      calendarFirstDay: 0,             // Japan: Sunday
      dateFormatHint: "YYYY年MM月DD日",
      preferClinicalTerminology: true, // 生理 (seiri) less taboo than alternatives
    },
  },
  {
    locales: ["zh", "zh-Hans", "zh-CN", "zh-SG"],
    label: "Chinese Simplified",
    source:
      "Hupka et al. 1997 (red=luck/celebration in ZH); W3C CLREQ 2021 " +
      "(Chinese Layout Requirements — line-height ≥ 1.6 for body); " +
      "Note: Green hat idiom (戴绿帽子) = infidelity — avoid green on relationship screens.",
    rules: {
      avoidRedAsDanger: true,
      avoidPureWhiteBackground: true,  // white/pale = mourning in ZH
      highDensityLayout: true,
      extendedLineHeight: 1.6,
      calendarFirstDay: 1,             // China: Monday (ISO-aligned)
      dateFormatHint: "YYYY年MM月DD日",
      avoidGreenForRelationshipContext: true,
    },
  },
  {
    locales: ["zh-Hant", "zh-TW", "zh-HK"],
    label: "Chinese Traditional",
    source: "Same as zh-Hans; Taiwan week starts Sunday.",
    rules: {
      avoidRedAsDanger: true,
      avoidPureWhiteBackground: true,
      highDensityLayout: true,
      extendedLineHeight: 1.6,
      calendarFirstDay: 0,             // Taiwan: Sunday
      dateFormatHint: "YYYY/MM/DD",
      avoidGreenForRelationshipContext: true,
    },
  },
  {
    locales: ["ko", "ko-KR"],
    label: "Korean",
    source:
      "Hupka et al. 1997 (red=joy in KR context); " +
      "Korea week starts Sunday.",
    rules: {
      avoidRedAsDanger: true,
      avoidPureWhiteBackground: true,
      highDensityLayout: true,
      calendarFirstDay: 0,             // Korea: Sunday
      dateFormatHint: "YYYY년 MM월 DD일",
    },
  },

  // -------------------------------------------------------------------------
  // INDIC SCRIPTS — extended line-height required
  // -------------------------------------------------------------------------
  {
    locales: ["hi", "hi-IN"],
    label: "Hindi (Devanagari)",
    source:
      "W3C Internationalization Activity (2022) — Devanagari glyphs extend " +
      "above/below baseline; minimum line-height 1.75 for readability. " +
      "India first day: Sunday (CLDR supplemental weekData).",
    rules: {
      extendedLineHeight: 1.75,
      calendarFirstDay: 0,
      dateFormatHint: "DD/MM/YYYY",
      preferClinicalTerminology: false, // colloquial 'mahvari' preferred
    },
  },
  {
    locales: ["bn", "bn-BD", "bn-IN"],
    label: "Bengali",
    source:
      "Bengali script (same script family as Devanagari) requires extended " +
      "line-height. W3C i18n 2022.",
    rules: {
      extendedLineHeight: 1.8,
      calendarFirstDay: 0,
      dateFormatHint: "DD/MM/YYYY",
    },
  },
  {
    locales: ["ml", "ml-IN"],
    label: "Malayalam",
    source:
      "Malayalam script has complex ligatures and stacked matras requiring " +
      "line-height ≥ 1.75. W3C i18n 2022.",
    rules: {
      extendedLineHeight: 1.75,
      calendarFirstDay: 0,
      dateFormatHint: "DD/MM/YYYY",
    },
  },

  // -------------------------------------------------------------------------
  // THAI
  // -------------------------------------------------------------------------
  {
    locales: ["th", "th-TH"],
    label: "Thai",
    source:
      "Thai script has vowel marks that stack above AND below consonants, " +
      "requiring line-height ≥ 2.0. W3C Thai Layout Requirements (TBREQ) 2023. " +
      "Thai calendar: Buddhist Era (add 543 years) — show Gregorian in parens.",
    rules: {
      extendedLineHeight: 2.0,
      calendarFirstDay: 0,             // Thailand: Sunday
      dateFormatHint: "DD/MM/YYYY",    // Gregorian
    },
  },

  // -------------------------------------------------------------------------
  // EUROPEAN — mostly ISO-aligned defaults, some variants
  // -------------------------------------------------------------------------
  {
    locales: ["de", "de-DE", "de-AT", "de-CH"],
    label: "German",
    source:
      "German text expands ~30% vs English (Microsoft i18n research 2019). " +
      "Ensure UI containers accommodate text expansion. Germany: Monday first day.",
    rules: {
      calendarFirstDay: 1,
      dateFormatHint: "DD.MM.YYYY",
    },
  },
  {
    locales: ["fr", "fr-FR", "fr-CA", "fr-BE"],
    label: "French",
    source:
      "French text expands ~15-20% vs English. Monday first day (EU ISO 8601).",
    rules: {
      calendarFirstDay: 1,
      dateFormatHint: "DD/MM/YYYY",
    },
  },
  {
    locales: ["es", "es-ES", "es-MX", "es-AR", "es-419"],
    label: "Spanish",
    source: "Spain/LatAm: Monday first day. US Hispanic: Sunday.",
    rules: {
      calendarFirstDay: 1,
      dateFormatHint: "DD/MM/YYYY",
    },
  },
  {
    locales: ["pt-BR"],
    label: "Portuguese (Brazil)",
    source: "Brazil week starts Sunday.",
    rules: {
      calendarFirstDay: 0,
      dateFormatHint: "DD/MM/YYYY",
    },
  },
  {
    locales: ["en", "en-US", "en-CA"],
    label: "English (North America)",
    source: "US/CA: Sunday first day; MM/DD/YYYY date format.",
    rules: {
      calendarFirstDay: 0,
      dateFormatHint: "MM/DD/YYYY",
    },
  },
  {
    locales: ["en-GB", "en-AU", "en-NZ", "en-IN"],
    label: "English (Commonwealth)",
    source: "Commonwealth: Monday first day; DD/MM/YYYY.",
    rules: {
      calendarFirstDay: 1,
      dateFormatHint: "DD/MM/YYYY",
    },
  },
];

// ---------------------------------------------------------------------------
// LOOKUP HELPER — find rules for a given locale
// ---------------------------------------------------------------------------

/**
 * Returns the CulturalRule for a given locale string, with fallback to
 * the language-only rule if the region-specific one is not found.
 * Example: "ar-MA" → checks "ar-MA" first, then "ar".
 */
export function getRulesForLocale(locale: string): CulturalTokenOverride {
  const exact = culturalRules.find(r => r.locales.includes(locale));
  if (exact) return exact.rules;

  const lang = locale.split("-")[0];
  const fallback = culturalRules.find(r =>
    r.locales.some(l => l === lang || l.startsWith(lang + "-"))
  );
  return fallback?.rules ?? { calendarFirstDay: 1, dateFormatHint: "DD/MM/YYYY" };
}

/**
 * Applies spacing density reduction for high-density locales (JP, ZH, KR).
 * Returns spacing multiplier: 1.0 = default, 0.8 = compact.
 */
export function getSpacingMultiplier(locale: string): number {
  const rules = getRulesForLocale(locale);
  return rules.highDensityLayout ? 0.8 : 1.0;
}
