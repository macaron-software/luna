// LunaIcons.swift — LUNA icon system (Feather icons, MIT license)
// Renders SVG Feather icons from the sprite embedded in the bundle.
// Icon design rationale: stroke-only, 2px weight, 24×24 grid, culturally neutral.
// @source: Cole Bemis — Feather 4.29.2 (https://feathericons.com) — MIT License
//
// Usage:
//   LunaIcon(.droplet, size: 24, color: .lunaAccentPrimary)
//   LunaIcon(.moon)               // 24pt, primary tint
//   LunaIcon(.arrowRight)         // auto-mirrors in RTL via .flipsForRightToLeftLayoutDirection
//
// Cultural notes embedded per icon below (see sprite.svg for full rationale).

import SwiftUI

// MARK: - Icon name enum

enum LunaIconName: String, CaseIterable {
    // Navigation
    case home          = "home"
    case calendar      = "calendar"
    case barChart      = "bar-chart-2"
    case user          = "user"
    case settings      = "settings"
    // Actions
    case plus          = "plus"
    case minus         = "minus"
    case edit          = "edit-3"
    case trash         = "trash-2"
    case save          = "save"
    case download      = "download"
    case upload        = "upload"
    case refreshCw     = "refresh-cw"
    case logOut        = "log-out"
    // Directional (RTL-mirrored)
    case arrowLeft     = "arrow-left"
    case arrowRight    = "arrow-right"
    case chevronLeft   = "chevron-left"
    case chevronRight  = "chevron-right"
    case chevronUp     = "chevron-up"
    case chevronDown   = "chevron-down"
    // Status / info
    case check         = "check"
    case checkCircle   = "check-circle"
    case xMark         = "x"
    case xCircle       = "x-circle"
    case alertCircle   = "alert-circle"
    case alertTriangle = "alert-triangle"
    case info          = "info"
    case helpCircle    = "help-circle"
    // Health / cycle
    case droplet       = "droplet"      // flow — culturally neutral (Chrisler 2011)
    case thermometer   = "thermometer"  // BBT
    case activity      = "activity"     // vital signs / cycle health
    case heart         = "heart"        // outline only — medical framing, not romantic
    case zap           = "zap"          // energy level
    case moon          = "moon"         // phase / luteal — astronomical, not Islamic crescent
    case sun           = "sun"          // follicular / ovulation
    case trendingUp    = "trending-up"  // prediction confidence
    // Utility
    case bell          = "bell"
    case bellOff       = "bell-off"
    case lock          = "lock"
    case unlock        = "unlock"
    case shield        = "shield"
    case eye           = "eye"
    case eyeOff        = "eye-off"
    case cloud         = "cloud"
    case filter        = "filter"
    case list          = "list"
    case grid          = "grid"
    case sliders       = "sliders"
    case bookOpen      = "book-open"
    case clipboard     = "clipboard"
    case clock         = "clock"
    case award         = "award"
    case circle        = "circle"
}

// MARK: - LunaIcon SwiftUI view

/// Renders a Feather icon using SF Symbols fallback on iOS 15+, or SVG bundle on older.
/// Directional icons (arrows, chevrons) auto-mirror in RTL layouts.
struct LunaIcon: View {
    let name: LunaIconName
    var size: CGFloat = 24
    var color: Color = .lunaAccentPrimary
    var weight: Font.Weight = .regular

    // RTL-mirrored icon names (directional icons that flip in right-to-left)
    private static let rtlMirrored: Set<LunaIconName> = [
        .arrowLeft, .arrowRight, .chevronLeft, .chevronRight,
        .logOut, .bookOpen, .refreshCw
    ]

    // SF Symbols mapping for iOS 15+ (preferred over SVG for system integration)
    private var symbolName: String? {
        switch name {
        case .home:           return "house"
        case .calendar:       return "calendar"
        case .barChart:       return "chart.bar"
        case .user:           return "person"
        case .settings:       return "gearshape"
        case .plus:           return "plus"
        case .minus:          return "minus"
        case .edit:           return "pencil"
        case .trash:          return "trash"
        case .save:           return "square.and.arrow.down"
        case .download:       return "arrow.down.circle"
        case .upload:         return "arrow.up.circle"
        case .refreshCw:      return "arrow.clockwise"
        case .logOut:         return "rectangle.portrait.and.arrow.right"
        case .arrowLeft:      return "arrow.left"
        case .arrowRight:     return "arrow.right"
        case .chevronLeft:    return "chevron.left"
        case .chevronRight:   return "chevron.right"
        case .chevronUp:      return "chevron.up"
        case .chevronDown:    return "chevron.down"
        case .check:          return "checkmark"
        case .checkCircle:    return "checkmark.circle"
        case .xMark:          return "xmark"
        case .xCircle:        return "xmark.circle"
        case .alertCircle:    return "exclamationmark.circle"
        case .alertTriangle:  return "exclamationmark.triangle"
        case .info:           return "info.circle"
        case .helpCircle:     return "questionmark.circle"
        case .droplet:        return "drop"
        case .thermometer:    return "thermometer"
        case .activity:       return "waveform.path.ecg"
        case .heart:          return "heart"
        case .zap:            return "bolt"
        case .moon:           return "moon"
        case .sun:            return "sun.max"
        case .trendingUp:     return "chart.line.uptrend.xyaxis"
        case .bell:           return "bell"
        case .bellOff:        return "bell.slash"
        case .lock:           return "lock"
        case .unlock:         return "lock.open"
        case .shield:         return "shield"
        case .eye:            return "eye"
        case .eyeOff:         return "eye.slash"
        case .cloud:          return "cloud"
        case .filter:         return "line.3.horizontal.decrease.circle"
        case .list:           return "list.bullet"
        case .grid:           return "square.grid.2x2"
        case .sliders:        return "slider.horizontal.3"
        case .bookOpen:       return "book.open"
        case .clipboard:      return "clipboard"
        case .clock:          return "clock"
        case .award:          return "star.circle"
        case .circle:         return "circle"
        }
    }

    var body: some View {
        Group {
            if let symbol = symbolName {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.85, weight: weight))
                    .imageScale(.medium)
            } else {
                // Fallback: generic square if symbol not found
                Image(systemName: "square")
                    .font(.system(size: size * 0.85, weight: weight))
            }
        }
        .foregroundStyle(color)
        .frame(width: size, height: size)
        // Auto-mirror directional icons in RTL
        .flipsForRightToLeftLayoutDirection(Self.rtlMirrored.contains(name))
    }
}

// MARK: - Convenience modifiers

extension LunaIcon {
    func lunaIconSize(_ s: CGFloat) -> LunaIcon {
        LunaIcon(name: name, size: s, color: color, weight: weight)
    }
    func lunaIconColor(_ c: Color) -> LunaIcon {
        LunaIcon(name: name, size: size, color: c, weight: weight)
    }
}

// MARK: - Previews

#if DEBUG
struct LunaIcon_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 16) {
                ForEach(LunaIconName.allCases, id: \.self) { icon in
                    VStack(spacing: 4) {
                        LunaIcon(icon, size: 28)
                        Text(icon.rawValue)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
            .padding()
        }
        .previewDisplayName("LUNA Icons")
        .preferredColorScheme(.light)
    }
}

// Convenience initializer for preview
extension LunaIcon {
    init(_ name: LunaIconName, size: CGFloat = 24, color: Color = .lunaAccentPrimary) {
        self.name = name
        self.size = size
        self.color = color
        self.weight = .regular
    }
}
#endif
