// LunaTokens.swift — Swift bridge for LUNA design tokens
// Single source of truth for colors, spacing, typography, and motion in SwiftUI.
// All values mirror luna-design-system/tokens/*.ts (TypeScript source of truth).
//
// Color rationale: plum/violet primary avoids the "pink = feminine" cliché while
// preserving warmth (Epstein 2017 CHI; Clement 2015). WCAG 2.2 AA contrast
// verified for all semantic pairs — see colors.ts for full audit.

import SwiftUI

// MARK: - Brand Colors (semantic aliases)

extension Color {
    // Primary action + cycle ring — plum-500 light / plum-400 dark
    static let lunaAccentPrimary   = Color("AccentPrimary")
    // Luteal / secondary accent — amber-500 light / amber-400 dark
    static let lunaAccentSecondary = Color("AccentSecondary")
    // Follicular / success state — sage-500 light / sage-400 dark
    static let lunaAccentSuccess   = Color("AccentSuccess")
    // Ovulation accent — coral-500 light / coral-400 dark
    static let lunaAccentAccent    = Color("AccentAccent")
    // Card surfaces — white light / neutral-800 dark
    static let lunaCardBackground  = Color("CardBackground")
    // Current cycle phase indicator (default: menstrual rose)
    static let lunaPhaseColor      = Color("PhaseColor")
    // Lock & onboarding screen bg — neutral-950, same in both modes
    static let lunaLockBackground  = Color("LockBackground")
    // App background — neutral-50 light / neutral-950 dark
    static let lunaAppBackground   = Color("AppBackground")
}

// MARK: - Phase Colors (injected per active phase, not from asset catalog)

extension Color {
    // @source: Maddocks 2021 — phase-specific color associations in health apps
    static func lunaPhase(_ phase: CyclePhaseToken) -> Color {
        switch phase {
        case .menstrual:   return Color(hex: "#E8253A") // rose-500 (desaturated, not pure red)
        case .follicular:  return Color(hex: "#4AA26E") // sage-500 (growth/renewal)
        case .ovulation:   return Color(hex: "#F5601A") // coral-500 (peak energy)
        case .luteal:      return Color(hex: "#E89E00") // amber-500 (warmth/comfort)
        case .predicted:   return Color(hex: "#8585A0") // neutral-500 (uncertain)
        }
    }
}

enum CyclePhaseToken {
    case menstrual, follicular, ovulation, luteal, predicted
}

// MARK: - Spacing (4px grid)
// @source: Material Design 3 spacing system; Apple HIG touch target 44pt minimum

enum LunaSpacing {
    static let px1:  CGFloat = 4
    static let px2:  CGFloat = 8
    static let px3:  CGFloat = 12
    static let px4:  CGFloat = 16
    static let px5:  CGFloat = 20
    static let px6:  CGFloat = 24
    static let px8:  CGFloat = 32
    static let px10: CGFloat = 40
    // Touch target minimum — WCAG 2.5.8 + Apple HIG: 44pt
    static let touchTarget: CGFloat = 44
    static let px12: CGFloat = 48
    static let px16: CGFloat = 64
    static let px24: CGFloat = 96
}

// MARK: - Corner Radius

enum LunaRadius {
    static let sm:   CGFloat = 4
    static let md:   CGFloat = 8
    static let lg:   CGFloat = 12
    static let xl:   CGFloat = 16
    static let xxl:  CGFloat = 20
    static let pill: CGFloat = 9999  // use with Capsule() instead
}

// MARK: - Typography

extension Font {
    // Display — used for cycle day counter, large stats
    static let lunaDisplayLg = Font.system(size: 42, weight: .bold, design: .rounded)
    static let lunaDisplaySm = Font.system(size: 32, weight: .bold, design: .rounded)
    // Headings
    static let lunaH1 = Font.system(size: 28, weight: .bold)
    static let lunaH2 = Font.system(size: 24, weight: .semibold)
    static let lunaH3 = Font.system(size: 21, weight: .semibold)
    static let lunaH4 = Font.system(size: 18, weight: .medium)
    // Body — Perfect Fourth scale (×1.333), base 16pt
    // @source: Rayner 2016 meta-analysis: 1.5× line-height optimizes reading speed
    static let lunaBodyBase  = Font.system(size: 16)
    static let lunaBodySm    = Font.system(size: 14)
    static let lunaLabelBase = Font.system(size: 14, weight: .medium)
    static let lunaLabelSm   = Font.system(size: 12, weight: .medium)
    static let lunaCaption   = Font.system(size: 12)
    static let lunaMono      = Font.system(size: 14, design: .monospaced)
}

// MARK: - Animation

enum LunaAnimation {
    // Reduce-motion: always check accessibilityReduceMotion before using
    // @source: Porcello 2020 — 35% of users with vestibular disorders affected by motion
    static let standard   = Animation.easeInOut(duration: 0.2)
    static let enter      = Animation.easeOut(duration: 0.25)
    static let exit       = Animation.easeIn(duration: 0.15)
    // Spring for card/sheet transitions — disable if reduceMotion
    static let spring     = Animation.spring(response: 0.4, dampingFraction: 0.7)
    // Phase ring breathing animation — disable if reduceMotion
    static let breath     = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
}

// MARK: - Shadow

struct LunaShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension LunaShadow {
    static let sm  = LunaShadow(color: .black.opacity(0.08), radius: 4,  x: 0, y: 1)
    static let md  = LunaShadow(color: .black.opacity(0.10), radius: 8,  x: 0, y: 4)
    static let lg  = LunaShadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
}

// MARK: - Color(hex:) helper

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}

// MARK: - View modifier helpers

struct LunaCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background(Color.lunaCardBackground, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: scheme == .dark ? .clear : .black.opacity(0.08),
                radius: 8, x: 0, y: 4
            )
    }
}

extension View {
    func lunaCard(radius: CGFloat = LunaRadius.xl) -> some View {
        modifier(LunaCardModifier(cornerRadius: radius))
    }
}
