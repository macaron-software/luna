import SwiftUI

/// Point d'entrée de navigation — gère onboarding / lock / main tabs
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingView()
            } else if appState.isLocked {
                LockView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isLocked)
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("tab_today", systemImage: "moon.stars.fill")
                }
                .accessibilityLabel(Text("tab_today_a11y"))

            CalendarView()
                .tabItem {
                    Label("tab_calendar", systemImage: "calendar")
                }
                .accessibilityLabel(Text("tab_calendar_a11y"))

            InsightsView()
                .tabItem {
                    Label("tab_insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .accessibilityLabel(Text("tab_insights_a11y"))

            SettingsView()
                .tabItem {
                    Label("tab_settings", systemImage: "person.circle")
                }
                .accessibilityLabel(Text("tab_settings_a11y"))
        }
        .tint(Color("AccentPrimary"))
    }
}
