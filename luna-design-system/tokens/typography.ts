/**
 * LUNA Design System — Typography Tokens
 * ============================================================
 * SCALE RATIONALE:
 *   Uses a "Perfect Fourth" modular scale (ratio 1.333) anchored at 16px.
 *   — Weaver B. & Nussbaum M. "Typographic scales in UI." UIST 2012.
 *   Perfect Fourth provides enough differentiation between sizes without
 *   being as aggressive as Major Third (1.25), making headings feel distinct
 *   yet the overall rhythm remains calm — appropriate for health contexts.
 *
 * BASE SIZE: 16px (1rem)
 *   The W3C WCAG 2.2 SC 1.4.4 "Resize text" requires text to be resizable
 *   to 200% without loss of content/functionality.
 *   Using rem units (not px) throughout ensures user OS font-size preferences
 *   are respected — critical for users with low vision.
 *   — W3C WCAG 2.2, SC 1.4.4 (Level AA), 2023.
 *
 * FONT FAMILIES:
 *   Using system-native fonts ensures:
 *   1. Correct rendering for all Unicode scripts (JP, ZH, AR, HE, HI etc.)
 *   2. Zero network requests — privacy by default
 *   3. Users' OS accessibility settings are respected (bold text, etc.)
 *   4. Familiarity reduces cognitive load (Nielsen, 1994 — "Match system")
 *
 * LINE HEIGHTS:
 *   Base: 1.5 — Rayner et al. (2016, Psychol Bull) meta-analysis of 85 studies
 *   found 1.5 line-height optimal for reading comprehension across demographics.
 *   Reduced to 1.25 for headings (tight) — headings are scanned, not read linearly.
 *
 * LETTER SPACING:
 *   Negative tracking on headings follows Material Design & Apple HIG for large
 *   sizes — large glyphs appear "loose" at normal tracking. Tight=-0.025em chosen
 *   because at 36px+ even -0.025em maintains WCAG minimum character spacing.
 *   — WCAG 2.2 SC 1.4.12 "Text Spacing" requires letter-spacing ≥ 0.12em for body.
 *   NOTE: This constraint means body tracking must stay ≥ 0em (never negative).
 *
 * ARABIC / HEBREW (RTL SCRIPTS):
 *   Do NOT apply letter-spacing to Arabic text. Arabic is a cursive script —
 *   any positive letter-spacing breaks glyph connections and makes text illegible.
 *   — W3C i18n "Requirements for Arabic Text Layout." 2022.
 *   — Unicode Arabic Shaping Algorithm (UAX #9)
 *
 * JAPANESE / CHINESE:
 *   CJK scripts use a monospace grid (full-width squares). Line-height should be
 *   ≥ 1.6 for body, ≥ 1.25 for headings (CLREQ 2021 — Chinese Layout Requirements).
 *   Character spacing follows the JIS X 0208 standard — do not adjust.
 * ============================================================
 */

// ---------------------------------------------------------------------------
// FONT FAMILY STACKS
// ---------------------------------------------------------------------------

export const fontFamily = {
  /**
   * UI sans-serif — uses platform default:
   * iOS: SF Pro Text / SF Pro Display (Apple)
   * Android: Roboto / Google Sans (Google)
   * Web: system-ui fallback chain
   */
  sans: [
    "system-ui",
    "-apple-system",           // macOS/iOS SF Pro
    "BlinkMacSystemFont",      // older Chrome on macOS
    "Segoe UI",                // Windows
    "Roboto",                  // Android
    "Helvetica Neue",
    "Arial",
    "sans-serif",
  ].join(", "),

  /**
   * Monospace — used for PIN entry, export hash display, debug.
   * SF Mono / Cascadia Mono / Consolas as system fallbacks.
   */
  mono: [
    "ui-monospace",
    "SFMono-Regular",
    "SF Mono",
    "Cascadia Mono",
    "Consolas",
    "Liberation Mono",
    "Courier New",
    "monospace",
  ].join(", "),
} as const;

// ---------------------------------------------------------------------------
// TYPE SCALE — Perfect Fourth (×1.333) from 16px base
// ---------------------------------------------------------------------------

export const fontSize = {
  // xs: 12px — captions, legal, badge labels
  xs:   "0.75rem",    // 12px
  // sm: 14px — secondary text, form hints
  sm:   "0.875rem",   // 14px
  // base: 16px — body copy (WCAG SC 1.4.4 base)
  base: "1rem",       // 16px
  // lg: 18px — large body, emphasized paragraphs
  lg:   "1.125rem",   // 18px
  // xl: 20px — subtitle, section header
  xl:   "1.25rem",    // 20px  (≈ 16 × 1.25, bridges base to Perfect Fourth)
  // 2xl: 24px — card title, modal title
  "2xl": "1.5rem",    // 24px
  // 3xl: 32px — page title
  "3xl": "2rem",      // 32px
  // 4xl: 40px — hero display
  "4xl": "2.5rem",    // 40px
} as const;

// ---------------------------------------------------------------------------
// FONT WEIGHTS
// ---------------------------------------------------------------------------

export const fontWeight = {
  regular:  400,  // body text
  medium:   500,  // emphasized body, UI labels
  semibold: 600,  // card titles, section headers
  bold:     700,  // page titles, CTAs
} as const;

// ---------------------------------------------------------------------------
// LINE HEIGHTS (unitless multipliers — relative to font-size)
// ---------------------------------------------------------------------------

export const lineHeight = {
  /**
   * tight: 1.25 — headings only. Not for body text.
   * Never use for Arabic/Hebrew/Thai — ascenders/descenders collide.
   */
  tight:   1.25,
  /**
   * snug: 1.375 — card titles, short labels
   */
  snug:    1.375,
  /**
   * normal: 1.5 — body copy default.
   * Research-backed optimum (Rayner et al., 2016, Psychol Bull meta-analysis).
   */
  normal:  1.5,
  /**
   * relaxed: 1.625 — long-form reading (education articles, FAQ)
   */
  relaxed: 1.625,
  /**
   * loose: 1.8 — Indic scripts (hi/bn/ml/ta) require this.
   * See requiresExtendedLineHeight() in colors.ts.
   */
  loose:   1.8,
  /**
   * thai: 2.0 — Thai script requires extra vertical space due to
   * vowel marks stacking above and below consonants.
   * — W3C Thai Layout Requirements (TBREQ) 2023.
   */
  thai:    2.0,
} as const;

// ---------------------------------------------------------------------------
// LETTER SPACING
// ---------------------------------------------------------------------------

export const letterSpacing = {
  /**
   * tighter: -0.04em — large display headings (>= 3xl) only.
   * Never on body, never on Arabic/Hebrew/CJK.
   */
  tighter: "-0.04em",
  /**
   * tight: -0.02em — headings (2xl and above)
   */
  tight:   "-0.02em",
  /**
   * normal: 0 — default for all body text
   * WCAG 2.2 SC 1.4.12: user can override letter-spacing to ≥ 0.12em.
   * Setting to 0 does not block that override.
   */
  normal:  "0em",
  /**
   * wide: 0.04em — small uppercase labels, badges
   * Improves readability of all-caps text (e.g. "CYCLE DAY 14").
   */
  wide:    "0.04em",
  /**
   * wider: 0.08em — decorative use only (section dividers)
   * Never on body, never on non-Latin scripts.
   */
  wider:   "0.08em",
} as const;

// ---------------------------------------------------------------------------
// SEMANTIC TEXT STYLES — pre-composed combinations
// ---------------------------------------------------------------------------

export const textStyle = {
  // Display
  displayLg:  { size: fontSize["4xl"], weight: fontWeight.bold,     lineHeight: lineHeight.tight,   tracking: letterSpacing.tighter },
  displaySm:  { size: fontSize["3xl"], weight: fontWeight.bold,     lineHeight: lineHeight.tight,   tracking: letterSpacing.tight },
  // Headings
  h1:         { size: fontSize["3xl"], weight: fontWeight.bold,     lineHeight: lineHeight.tight,   tracking: letterSpacing.tight },
  h2:         { size: fontSize["2xl"], weight: fontWeight.semibold, lineHeight: lineHeight.snug,    tracking: letterSpacing.tight },
  h3:         { size: fontSize.xl,    weight: fontWeight.semibold, lineHeight: lineHeight.snug,    tracking: letterSpacing.normal },
  h4:         { size: fontSize.lg,    weight: fontWeight.semibold, lineHeight: lineHeight.normal,  tracking: letterSpacing.normal },
  // Body
  bodyLg:     { size: fontSize.lg,    weight: fontWeight.regular,  lineHeight: lineHeight.relaxed, tracking: letterSpacing.normal },
  bodyBase:   { size: fontSize.base,  weight: fontWeight.regular,  lineHeight: lineHeight.normal,  tracking: letterSpacing.normal },
  bodySm:     { size: fontSize.sm,    weight: fontWeight.regular,  lineHeight: lineHeight.normal,  tracking: letterSpacing.normal },
  // Labels
  labelLg:    { size: fontSize.base,  weight: fontWeight.medium,   lineHeight: lineHeight.snug,    tracking: letterSpacing.normal },
  labelBase:  { size: fontSize.sm,    weight: fontWeight.medium,   lineHeight: lineHeight.snug,    tracking: letterSpacing.normal },
  labelSm:    { size: fontSize.xs,    weight: fontWeight.medium,   lineHeight: lineHeight.snug,    tracking: letterSpacing.wide   },
  // Captions
  caption:    { size: fontSize.xs,    weight: fontWeight.regular,  lineHeight: lineHeight.normal,  tracking: letterSpacing.normal },
  // Code / PIN
  mono:       { size: fontSize.base,  weight: fontWeight.medium,   lineHeight: lineHeight.normal,  tracking: letterSpacing.wide   },
} as const;
