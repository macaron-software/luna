import SwiftUI
import LocalAuthentication
import UIKit

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPanicWipeConfirmation: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var notifDailyLog: Bool = true
    @State private var notifPeriodReminder: Bool = true
    @State private var notifFertileWindow: Bool = false
    @State private var notifBBTReminder: Bool = false
    @State private var iCloudSync: Bool = false
    @State private var lockEnabled: Bool = true
    @State private var pillReminderEnabled: Bool = false
    @State private var pillReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var healthKitEnabled: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationStack {
            List {

                // ── Profil ────────────────────────────────────────────
                Section {
                    NavigationLink {
                        ProfileEditView()
                    } label: {
                        LabeledContent("settings_profile_label", value: appState.userName ?? "–")
                    }
                    .accessibilityLabel(Text("settings_profile_a11y"))
                } header: {
                    Text("settings_section_profile")
                }

                // ── Vie privée & Sécurité ─────────────────────────────
                Section {
                    Toggle(isOn: $lockEnabled) {
                        Label("settings_lock_label", systemImage: "faceid")
                    }
                    .onChange(of: lockEnabled) { new in
                        appState.lockEnabled = new
                    }

                    HStack {
                        Label("settings_storage_label", systemImage: "internaldrive")
                        Spacer()
                        Text("settings_storage_local")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Toggle(isOn: $iCloudSync) {
                        Label("settings_icloud_label", systemImage: "icloud")
                    }
                    .disabled(true) // Tier 2 feature

                    // Badge trust
                    HStack(spacing: 6) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("settings_trust_badge")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("privacy_badge_a11y"))

                    Button(role: .destructive) {
                        showPanicWipeConfirmation = true
                    } label: {
                        Label("settings_delete_all_label", systemImage: "trash")
                    }
                    .accessibilityLabel(Text("settings_delete_all_a11y"))
                    .accessibilityHint(Text("settings_delete_all_hint_a11y"))
                } header: {
                    Text("settings_section_privacy")
                }

                // ── Bien-être & Accessibilité (a11y psy) ─────────────
                Section {
                    Toggle(isOn: Binding(
                        get: { appState.calmMode },
                        set: { appState.calmMode = $0 }
                    )) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings_calm_mode")
                                Text("settings_calm_mode_description")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "leaf")
                        }
                    }
                    .accessibilityHint(Text("settings_calm_mode_description"))
                } header: {
                    Text("settings_section_wellbeing")
                }

                // ── Notifications ─────────────────────────────────────
                Section {
                    Toggle(isOn: $notifDailyLog) {
                        Text("notif_daily_log_label")
                    }
                    .accessibilityLabel(Text("notif_daily_log_a11y"))

                    Toggle(isOn: $notifPeriodReminder) {
                        Text("notif_period_reminder_label")
                    }

                    Toggle(isOn: $notifFertileWindow) {
                        Text("notif_fertile_window_label")
                    }

                    Toggle(isOn: $notifBBTReminder) {
                        Text("notif_bbt_reminder_label")
                    }

                    NavigationLink("settings_tracking_mode") {
                        TrackingModeView()
                    }
                    .frame(minHeight: 44)
                } header: {
                    Text("settings_section_notifications")
                }

                // ── Rappel contraception ──────────────────────────────
                Section("settings_pill_reminder_section") {
                    Toggle("settings_pill_reminder_toggle", isOn: $pillReminderEnabled)
                        .frame(minHeight: 44)
                        .onChange(of: pillReminderEnabled) { enabled in
                            if enabled {
                                let fmt = DateFormatter()
                                fmt.dateFormat = "HH:mm"
                                NotificationManager.shared.schedulePillReminder(timeString: fmt.string(from: pillReminderTime))
                            } else {
                                NotificationManager.shared.cancelPillReminder()
                            }
                        }
                    if pillReminderEnabled {
                        DatePicker("settings_pill_time", selection: $pillReminderTime,
                                   displayedComponents: .hourAndMinute)
                            .frame(minHeight: 44)
                            .onChange(of: pillReminderTime) { newTime in
                                let fmt = DateFormatter()
                                fmt.dateFormat = "HH:mm"
                                NotificationManager.shared.schedulePillReminder(timeString: fmt.string(from: newTime))
                            }
                    }
                }

                // ── Santé (HealthKit) ─────────────────────────────────
                Section("settings_healthkit_section") {
                    Toggle("settings_healthkit_toggle", isOn: $healthKitEnabled)
                        .frame(minHeight: 44)
                        .onChange(of: healthKitEnabled) { enabled in
                            if enabled { Task { await requestHealthKit() } }
                        }
                }

                // ── Intégrations ──────────────────────────────────────
                Section {
                    NavigationLink {
                        HealthKitSettingsView()
                    } label: {
                        Label("settings_health_label", systemImage: "heart")
                    }

                    Button("export_csv_label") { exportCSV() }
                        .frame(minHeight: 44)

                    Button {
                        showExportSheet = true
                    } label: {
                        Label("settings_export_label", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("settings_section_integrations")
                }

                // ── À propos ──────────────────────────────────────────
                Section {
                    LabeledContent("settings_version_label", value: appVersion)
                        .foregroundStyle(.secondary)
                    Link(destination: URL(string: "https://luna-app.privacy")!) {
                        Label("settings_privacy_policy_label", systemImage: "lock.shield")
                    }
                } header: {
                    Text("settings_section_about")
                } footer: {
                    Text("settings_footer_no_server")
                        .font(.caption)
                }

            }
            .navigationTitle("tab_settings")
            .confirmationDialog(
                Text("panic_wipe_confirm_title"),
                isPresented: $showPanicWipeConfirmation,
                titleVisibility: .visible
            ) {
                Button("panic_wipe_confirm_button", role: .destructive) {
                    authenticateAndWipe()
                }
                Button("cancel_button", role: .cancel) {}
            } message: {
                Text("panic_wipe_confirm_message")
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheetView()
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private func exportCSV() {
        guard let engine = appState.engine else { return }
        Task {
            let to = ISO8601DateFormatter().string(from: Date())
            let from = ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .year, value: -2, to: Date())!)
            if let csv = try? engine.exportLogsCsv(from: from, to: to) {
                await MainActor.run {
                    shareItems = [csv]
                    showShareSheet = true
                }
            }
        }
    }

    private func requestHealthKit() async {
        guard #available(iOS 16.0, *) else { return }
        let ok = await HealthKitManager.shared.requestAuthorization()
        await MainActor.run { healthKitEnabled = ok }
    }

    private func authenticateAndWipe() {
        let ctx = LAContext()
        ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: NSLocalizedString("panic_wipe_biometric_reason", comment: "")
        ) { success, _ in
            guard success else { return }
            Task { @MainActor in
                do {
                    try appState.engine?.panicWipe()
                } catch {
                    // Erreur attendue WipedSuccessfully — reset UI
                }
                appState.isVaultOpen = false
                appState.engine = nil
                UIAccessibility.post(
                    notification: .announcement,
                    argument: NSLocalizedString("panic_wipe_done_a11y", comment: "")
                )
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - ProfileEditView (stub)

struct ProfileEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var body: some View {
        Form {
            Section("settings_profile_label") {
                TextField("profile_name_placeholder", text: $name)
            }
        }
        .navigationTitle("settings_profile_label")
        .onAppear { name = appState.userName ?? "" }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("save_button") {
                    appState.userName = name
                    dismiss()
                }
            }
        }
    }
}

// MARK: - HealthKitSettingsView (stub)

struct HealthKitSettingsView: View {
    @State private var syncEnabled: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle("settings_health_sync_toggle", isOn: $syncEnabled)
            } footer: {
                Text("settings_health_sync_footer")
            }
        }
        .navigationTitle("settings_health_label")
    }
}

// MARK: - ExportSheetView

struct ExportSheetView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    export(format: "pdf")
                } label: {
                    Label("export_pdf_label", systemImage: "doc.richtext")
                }
                .frame(minHeight: 44)

                Button {
                    export(format: "csv")
                } label: {
                    Label("export_csv_label", systemImage: "tablecells")
                }
                .frame(minHeight: 44)

                Button {
                    export(format: "backup")
                } label: {
                    Label("export_encrypted_backup_label", systemImage: "lock.doc")
                }
                .frame(minHeight: 44)
            }
            .navigationTitle("settings_export_label")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel_button") { dismiss() }
                }
            }
        }
    }

    private func export(format: String) {
        // TODO: implémenter les exports depuis LunaEngine
        dismiss()
    }
}
