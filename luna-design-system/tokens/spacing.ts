/**
 * LUNA Design System — Spacing, Radius, Shadow, Motion Tokens
 * ============================================================
 * SPACING — 4px base grid
 *   4px grid is the most widely adopted in UI design (Material Design, Apple HIG,
 *   Ant Design) because 4 divides evenly by 2, 4, 8, 16 — enables consistent
 *   halving/doubling without fractional pixels on any display density.
 *   — Google Material Design 3 "Layout grid" spec, 2022.
 *   — Apple HIG "Layout > Spacing", 2023.
 *
 * TOUCH TARGET MINIMUM: 44×44pt (iOS) / 48×48dp (Android)
 *   — Apple HIG Accessibility, 2023.
 *   — Android Accessibility guidelines (Material 3), 2022.
 *   — W3C WCAG 2.2 SC 2.5.8 "Target Size (Minimum)" requires 24×24 CSS px min,
 *     recommended 44×44.
 *   Use spacing[11] (44px) as minimum interactive element dimension.
 *
 * MOTION — reduce-motion is a first-class concern
 *   ~35% of users with vestibular disorders report motion sickness from app
 *   animations (Porcello & Hurst, 2020, ASSETS). iOS/Android expose
 *   "Reduce Motion" system settings that must be respected.
 *   — Porcello C. et al. "Reduce Motion." ASSETS 2020.
 *   — CSS: @media (prefers-reduced-motion: reduce)
 *   — iOS: UIAccessibility.isReduceMotionEnabled
 *   — Android: Settings.Global.TRANSITION_ANIMATION_SCALE == 0
 *
 *   LUNA rule: when reduce-motion is ON, replace all animations with
 *   instant transitions (duration → 0ms) or cross-fades (opacity only).
 * ============================================================
 */

// ---------------------------------------------------------------------------
// SPACING — 4px grid
// ---------------------------------------------------------------------------

export const spacing = {
  0:  "0px",
  // 1 = 4px — tight inline gaps, icon-text padding
  1:  "4px",
  // 2 = 8px — small gaps, chip inner padding
  2:  "8px",
  // 3 = 12px — list item vertical padding
  3:  "12px",
  // 4 = 16px — default card padding, form field height supplement
  4:  "16px",
  // 5 = 20px — section content padding
  5:  "20px",
  // 6 = 24px — card gap, section gap
  6:  "24px",
  // 7 = 28px
  7:  "28px",
  // 8 = 32px — screen horizontal margin (phone)
  8:  "32px",
  // 9 = 36px
  9:  "36px",
  // 10 = 40px — bottom sheet handle area
  10: "40px",
  // 11 = 44px — MINIMUM touch target size (Apple HIG / WCAG 2.5.8)
  11: "44px",
  // 12 = 48px — standard button height, minimum Android touch target
  12: "48px",
  // 14 = 56px — FAB size, prominent CTA
  14: "56px",
  // 16 = 64px — large icon / avatar
  16: "64px",
  // 20 = 80px — hero section padding
  20: "80px",
  // 24 = 96px — modal top padding
  24: "96px",
} as const;

// ---------------------------------------------------------------------------
// BORDER RADIUS
// ---------------------------------------------------------------------------

export const radius = {
  none: "0px",
  // sm: 4px — subtle rounding (badges, pills)
  sm:   "4px",
  // md: 8px — inputs, chips
  md:   "8px",
  // lg: 12px — cards
  lg:   "12px",
  // xl: 16px — bottom sheets, modals
  xl:   "16px",
  // 2xl: 20px — bottom sheet top corners
  "2xl": "20px",
  // 3xl: 24px — large modal, onboarding cards
  "3xl": "24px",
  // full: 9999px — pills, icon buttons, progress indicators
  full: "9999px",
} as const;

// ---------------------------------------------------------------------------
// SHADOWS / ELEVATION
// Warm-tinted shadows (plum-950/opacity) in light mode — matches brand palette.
// Dark mode uses deeper opacity without color tint (dark bg absorbs color).
// ---------------------------------------------------------------------------

export const shadow = {
  none:   "none",
  // sm: subtle — card resting state (light), list items
  sm:     "0 1px 3px rgba(30,5,64,0.08), 0 1px 2px rgba(30,5,64,0.04)",
  // md: floating — cards on scroll, dropdowns
  md:     "0 4px 8px rgba(30,5,64,0.10), 0 2px 4px rgba(30,5,64,0.06)",
  // lg: elevated — modals, bottom sheets
  lg:     "0 12px 24px rgba(30,5,64,0.12), 0 4px 8px rgba(30,5,64,0.08)",
  // xl: prominent — dialogs, auth screens
  xl:     "0 24px 48px rgba(30,5,64,0.16), 0 8px 16px rgba(30,5,64,0.10)",
  // inner: inset — pressed states, active inputs
  inner:  "inset 0 2px 4px rgba(30,5,64,0.06)",

  // Dark mode shadows (deeper opacity, no color tint)
  smDark: "0 1px 3px rgba(0,0,0,0.40)",
  mdDark: "0 4px 8px rgba(0,0,0,0.50)",
  lgDark: "0 12px 24px rgba(0,0,0,0.60)",
  xlDark: "0 24px 48px rgba(0,0,0,0.70)",
} as const;

// ---------------------------------------------------------------------------
// MOTION / ANIMATION TOKENS
// ---------------------------------------------------------------------------

export const duration = {
  /**
   * instant: 0ms — used when prefers-reduced-motion is ON.
   * Also used for state changes that must feel immediate (PIN digits).
   */
  instant:    0,
  /**
   * fast: 100ms — micro-interactions (toggle, checkbox check, icon swap).
   * Human perception threshold for "instantaneous" ≈ 100ms (Card et al., 1983).
   */
  fast:       100,
  /**
   * normal: 200ms — standard interaction feedback (button press, chip select).
   * Fits within the 150-300ms "unconscious" processing window.
   * — Doherty & Thadhani (1982) "Response time and productivity" IBM Systems J.
   */
  normal:     200,
  /**
   * slow: 300ms — page transitions, expand/collapse.
   * Material Design 3 standard page transition duration: 300ms.
   */
  slow:       300,
  /**
   * deliberate: 500ms — complex state changes (onboarding step, modal open).
   * Above 1000ms causes users to "lose context" (Nielsen, 1994).
   */
  deliberate: 500,
  /**
   * breath: 3000ms — breathing animation in menstrual phase cards.
   * Calming visual rhythm. Used ONLY when reduce-motion is OFF.
   */
  breath:     3000,
} as const;

export const easing = {
  /**
   * linear — progress bars, counters
   */
  linear:       "cubic-bezier(0, 0, 1, 1)",
  /**
   * easeIn — elements leaving screen
   */
  easeIn:       "cubic-bezier(0.4, 0, 1, 1)",
  /**
   * easeOut — elements entering screen (most common in UI).
   * Matches platform standard: iOS UIViewAnimationCurveEaseOut,
   * Android AccelerateDecelerateInterpolator.
   */
  easeOut:      "cubic-bezier(0, 0, 0.2, 1)",
  /**
   * easeInOut — shared axis transitions, value changes
   */
  easeInOut:    "cubic-bezier(0.4, 0, 0.2, 1)",
  /**
   * spring — delightful micro-interactions (save success, cycle start).
   * Slight overshoot (spring) communicates responsiveness without jarring.
   * Disabled when prefers-reduced-motion is ON.
   */
  spring:       "cubic-bezier(0.34, 1.56, 0.64, 1)",
} as const;

// ---------------------------------------------------------------------------
// BREAKPOINTS — screen size thresholds
// ---------------------------------------------------------------------------

export const breakpoint = {
  // xs: compact phone (< 375px) — older/small iPhones, some Androids
  xs:  375,
  // sm: standard phone (375–428px) — iPhone 14, Pixel 7
  sm:  428,
  // md: large phone / small tablet (428–768px) — iPad mini landscape
  md:  768,
  // lg: tablet (768–1024px) — iPad standard
  lg:  1024,
  // xl: large tablet / desktop (> 1024px)
  xl:  1280,
} as const;

// ---------------------------------------------------------------------------
// ICON SIZES — always square
// ---------------------------------------------------------------------------

export const iconSize = {
  // xs: 12px — decorative inline (never interactive)
  xs:  12,
  // sm: 16px — inline text icon (captions)
  sm:  16,
  // base: 20px — default icon in buttons, list items
  base: 20,
  // lg: 24px — standalone icons, nav bar
  lg:  24,
  // xl: 32px — section illustrations
  xl:  32,
  // 2xl: 40px — onboarding / empty state illustrations
  "2xl": 40,
  // 3xl: 48px — hero graphics
  "3xl": 48,
} as const;
