/**
 * luna-design-system/components/index.ts
 * Component specification tokens — the "contract" between design and native.
 *
 * Bridges TypeScript design tokens → iOS LunaTokens.swift + Android themes.xml.
 * Each spec describes intent, not implementation (Swift/Kotlin handle rendering).
 *
 * @source Rayner 2016 — touch target minimum 44pt for motor impairment users.
 * @source WCAG 2.5.8 — 24×24 absolute minimum (44×44 strongly recommended).
 */

import { colorTokens } from '../tokens/colors';
import { spacingTokens, touchTarget } from '../tokens/spacing';
import { typographyTokens } from '../tokens/typography';

// ─── Shared foundation ───────────────────────────────────────────────────────

export const cornerRadius = {
  none: 0,
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  '2xl': 24,
  full: 9999,
} as const;

export const elevation = {
  none: 0,
  sm: 1,    // card resting
  md: 4,    // bottom sheet
  lg: 8,    // modal overlay
  xl: 16,   // lock screen drawer
} as const;

// ─── Button ───────────────────────────────────────────────────────────────────

export interface ButtonSpec {
  /** Minimum touch target (must be ≥ 44pt iOS / 48dp Android). */
  minHeight: number;
  minWidth: number;
  paddingH: number;
  paddingV: number;
  cornerRadius: number;
  fontSize: number;
  fontWeight: 'medium' | 'semibold' | 'bold';
  /** Whether to show loading spinner instead of label. */
  hasLoadingState: boolean;
  /** Whether to support leading/trailing icons. */
  hasIcon: boolean;
}

export const buttonSpecs = {
  /** Primary CTA — filled plum background. */
  primary: {
    minHeight: touchTarget.ios,        // 44pt
    minWidth: 120,
    paddingH: spacingTokens[5],        // 20
    paddingV: spacingTokens[3],        // 12
    cornerRadius: cornerRadius.lg,     // 12
    fontSize: typographyTokens.scale.base,
    fontWeight: 'semibold',
    hasLoadingState: true,
    hasIcon: true,
    colors: {
      bg: colorTokens.semantic.interactive.default,
      fg: '#FFFFFF',
      bgHover: colorTokens.semantic.interactive.hover,
      bgDisabled: colorTokens.semantic.interactive.disabled,
    },
  } satisfies ButtonSpec & { colors: object },

  /** Secondary CTA — outlined plum border. */
  secondary: {
    minHeight: touchTarget.ios,
    minWidth: 100,
    paddingH: spacingTokens[4],        // 16
    paddingV: spacingTokens[3],        // 12
    cornerRadius: cornerRadius.lg,
    fontSize: typographyTokens.scale.base,
    fontWeight: 'medium',
    hasLoadingState: false,
    hasIcon: true,
    colors: {
      bg: 'transparent',
      fg: colorTokens.semantic.interactive.default,
      border: colorTokens.semantic.interactive.default,
      bgHover: colorTokens.primitive.plum[50],
    },
  } satisfies ButtonSpec & { colors: object },

  /** Ghost — text-only, no border. */
  ghost: {
    minHeight: touchTarget.ios,
    minWidth: 80,
    paddingH: spacingTokens[3],        // 12
    paddingV: spacingTokens[2],        // 8
    cornerRadius: cornerRadius.sm,
    fontSize: typographyTokens.scale.sm,
    fontWeight: 'medium',
    hasLoadingState: false,
    hasIcon: true,
    colors: {
      fg: colorTokens.semantic.interactive.default,
      bgHover: colorTokens.primitive.plum[50],
    },
  } satisfies ButtonSpec & { colors: object },

  /** Destructive — panic wipe / delete confirmations. */
  destructive: {
    minHeight: touchTarget.ios,
    minWidth: 120,
    paddingH: spacingTokens[5],
    paddingV: spacingTokens[3],
    cornerRadius: cornerRadius.lg,
    fontSize: typographyTokens.scale.base,
    fontWeight: 'semibold',
    hasLoadingState: true,
    hasIcon: false,
    colors: {
      bg: colorTokens.semantic.status.danger,
      fg: '#FFFFFF',
    },
  } satisfies ButtonSpec & { colors: object },
} as const;

// ─── Card ─────────────────────────────────────────────────────────────────────

export interface CardSpec {
  padding: number;
  cornerRadius: number;
  elevation: number;
  borderWidth: number;
}

export const cardSpecs = {
  /** Default content card (today summary, insight cards). */
  default: {
    padding: spacingTokens[4],         // 16
    cornerRadius: cornerRadius.xl,     // 16
    elevation: elevation.sm,
    borderWidth: 1,
    colors: {
      bg: 'CardBackground',            // xcassets color name
      border: colorTokens.semantic.border.default,
    },
  } satisfies CardSpec & { colors: object },

  /** Cycle phase card — colored accent border. */
  phase: {
    padding: spacingTokens[4],
    cornerRadius: cornerRadius.xl,
    elevation: elevation.none,
    borderWidth: 2,
    // border color set dynamically to CyclePhaseToken color
  } satisfies CardSpec,

  /** Insight card — slightly elevated, no border. */
  insight: {
    padding: spacingTokens[5],         // 20
    cornerRadius: cornerRadius['2xl'], // 24
    elevation: elevation.sm,
    borderWidth: 0,
  } satisfies CardSpec,
} as const;

// ─── Badge ────────────────────────────────────────────────────────────────────

export interface BadgeSpec {
  height: number;
  paddingH: number;
  cornerRadius: number;
  fontSize: number;
  fontWeight: 'medium' | 'semibold';
}

export const badgeSpecs = {
  /** Phase label badge (e.g. "Lutéale", "Folliculaire"). */
  phase: {
    height: 24,
    paddingH: spacingTokens[2],        // 8
    cornerRadius: cornerRadius.full,
    fontSize: typographyTokens.scale.xs,
    fontWeight: 'semibold',
  } satisfies BadgeSpec,

  /** Trust badge — "Données locales · Hors connexion". */
  trust: {
    height: 28,
    paddingH: spacingTokens[3],        // 12
    cornerRadius: cornerRadius.full,
    fontSize: typographyTokens.scale.xs,
    fontWeight: 'medium',
    colors: {
      bg: colorTokens.primitive.sage[50] ?? '#F0FBF4',
      fg: colorTokens.primitive.sage[700] ?? '#2D6A47',
      icon: colorTokens.primitive.sage[500],
    },
  } satisfies BadgeSpec & { colors: object },

  /** Prediction confidence — "Confiance : élevée". */
  confidence: {
    height: 24,
    paddingH: spacingTokens[2],
    cornerRadius: cornerRadius.full,
    fontSize: typographyTokens.scale.xs,
    fontWeight: 'medium',
  } satisfies BadgeSpec,
} as const;

// ─── Input ────────────────────────────────────────────────────────────────────

export interface InputSpec {
  height: number;
  paddingH: number;
  cornerRadius: number;
  fontSize: number;
  borderWidth: number;
  borderFocusWidth: number;
}

export const inputSpecs = {
  /** Standard text input (note, BBT value). */
  text: {
    height: touchTarget.ios,           // 44pt — a11y minimum
    paddingH: spacingTokens[3],        // 12
    cornerRadius: cornerRadius.md,     // 8
    fontSize: typographyTokens.scale.base,
    borderWidth: 1,
    borderFocusWidth: 2,
    colors: {
      bg: 'CardBackground',
      border: colorTokens.semantic.border.default,
      borderFocus: colorTokens.semantic.border.focus,
      label: colorTokens.semantic.content.secondary,
      placeholder: colorTokens.semantic.content.secondary,
    },
  } satisfies InputSpec & { colors: object },

  /** PIN input — 6 circular cells. */
  pin: {
    cellSize: 48,                      // 48×48pt — above minimum
    cornerRadius: cornerRadius.full,
    fontSize: typographyTokens.scale['2xl'],
    borderWidth: 2,
    borderFocusWidth: 3,
    filledColor: colorTokens.semantic.interactive.default,
    emptyColor: colorTokens.semantic.border.default,
  },
} as const;

// ─── BottomSheet ──────────────────────────────────────────────────────────────

export const bottomSheetSpec = {
  /** Drag handle. */
  handle: {
    width: 40,
    height: 4,
    cornerRadius: cornerRadius.full,
    topPadding: spacingTokens[2],      // 8
    bottomPadding: spacingTokens[3],   // 12
  },
  /** Content area. */
  content: {
    paddingH: spacingTokens[5],        // 20
    paddingBottom: spacingTokens[8],   // 32 (safe area + extra)
    cornerRadiusTop: cornerRadius['2xl'], // 24
  },
  /** Backdrop overlay opacity. */
  backdropOpacity: 0.4,
  /** Backdrop color — always dark regardless of theme. */
  backdropColor: '#000000',
  /** Available snap points: half screen or full screen. */
  snapPoints: ['50%', '90%'],
  /** Animation: spring — matches iOS UISheetPresentationController feel. */
  animation: {
    type: 'spring' as const,
    damping: 0.82,
    stiffness: 400,
  },
} as const;

// ─── SymptomChip ──────────────────────────────────────────────────────────────
// Used in LogSheet to multi-select symptoms.

export const symptomChipSpec = {
  height: touchTarget.ios,             // 44pt — a11y critical for frequent action
  paddingH: spacingTokens[3],          // 12
  cornerRadius: cornerRadius.full,
  fontSize: typographyTokens.scale.sm,
  fontWeight: 'medium' as const,
  /** Minimum horizontal spacing between chips (FlowLayout). */
  gapH: spacingTokens[2],             // 8
  /** Minimum vertical spacing between chip rows. */
  gapV: spacingTokens[2],             // 8
  colors: {
    bgDefault: 'CardBackground',
    bgSelected: colorTokens.semantic.interactive.default,
    fgDefault: colorTokens.semantic.content.primary,
    fgSelected: '#FFFFFF',
    borderDefault: colorTokens.semantic.border.default,
    borderSelected: colorTokens.semantic.interactive.default,
  },
} as const;

// ─── CycleProgressDonut ───────────────────────────────────────────────────────
// Home screen hero widget.

export const cycleDonutSpec = {
  outerDiameter: 200,
  innerDiameter: 140,              // donut hole
  strokeWidth: 12,
  trackColor: colorTokens.semantic.border.default,
  /** Progress color set dynamically from CyclePhaseToken. */
  gap: 4,                          // gap between segments (multi-phase view)
  /** Text inside donut. */
  dayLabel: {
    fontSize: typographyTokens.scale['4xl'],
    fontWeight: 'bold' as const,
  },
  phaseLabel: {
    fontSize: typographyTokens.scale.sm,
    fontWeight: 'medium' as const,
    color: colorTokens.semantic.content.secondary,
  },
} as const;

// ─── Re-exports for convenience ───────────────────────────────────────────────

export { cornerRadius as radius, elevation };
export type { ButtonSpec, CardSpec, BadgeSpec, InputSpec };
