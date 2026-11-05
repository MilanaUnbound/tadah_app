import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppPreferences.self) private var preferences
    @Environment(TaskDeleteUndoController.self) private var taskDeleteUndo

    @Query(sort: [SortDescriptor(\Task.dateKey), SortDescriptor(\Task.title)]) private var tasks: [Task]
    @Query(sort: \Project.name) private var projects: [Project]

    @State private var exportURL: URL?
    @State private var exportErrorMessage: String?
    @State private var importErrorMessage: String?
    @State private var deleteErrorMessage: String?
    @State private var notificationDeniedMessage: String?
    @State private var isImporting = false
    @State private var pendingImportURL: URL?
    @State private var showImportConfirm = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: 0) {
                    sectionHeader("Appearance", topPadding: 4)

                    AppearanceModePicker(selection: Binding(
                        get: { preferences.appearanceMode },
                        set: { preferences.appearanceMode = $0 }
                    ))

                    sectionHeader("Data", topPadding: 14)

                    SettingRow(
                        icon: Image(systemName: "arrow.down.circle")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(AppTheme.exportBlue),
                        label: "Export data",
                        hint: "Download all tasks and projects"
                    ) {
                        SettingsActionButton(style: .save) {
                            export()
                        }
                    }

                    SettingRow(
                        icon: Image(systemName: "arrow.up.circle")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(AppTheme.importGreen),
                        label: "Import data",
                        hint: "Restore from a backup file"
                    ) {
                        SettingsActionButton(style: .load) {
                            isImporting = true
                        }
                    }

                    SettingRow(
                        icon: Image(systemName: "trash")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(AppTheme.deleteRed),
                        label: "Delete all data",
                        hint: "Permanently remove all tasks and projects"
                    ) {
                        SettingsActionButton(style: .delete) {
                            showDeleteConfirm = true
                        }
                    }

                    sectionHeader("Focus", topPadding: 14)

                    SettingRow(
                        icon: Image(systemName: "bell")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(AppTheme.reminderPink),
                        label: "Daily reminder",
                        hint: "Get nudged once a day"
                    ) {
                        SettingsToggle(isOn: Binding(
                            get: { preferences.notificationsEnabled },
                            set: { newValue in
                                preferences.notificationsEnabled = newValue
                                _Concurrency.Task {
                                    await handleNotificationsChange(enabled: newValue)
                                }
                            }
                        ))
                    }

                    SettingRow(
                        icon: Text("🎉")
                            .font(.system(size: 17)),
                        label: "Daily task goal",
                        hint: "Minimum tasks to feel done"
                    ) {
                        HStack(spacing: 10) {
                            Button {
                                preferences.streakGoal = max(1, preferences.streakGoal - 1)
                            } label: {
                                Text("−")
                                    .font(.spaceGrotesk(.medium, size: 16))
                                    .foregroundStyle(theme.text)
                                    .frame(width: 28, height: 28)
                                    .background(theme.btnBg, in: Circle())
                            }
                            .buttonStyle(.plain)

                            Text("\(preferences.streakGoal)")
                                .font(.spaceGrotesk(.semibold, size: 15))
                                .foregroundStyle(theme.text)
                                .frame(minWidth: 16)

                            Button {
                                preferences.streakGoal = min(20, preferences.streakGoal + 1)
                            } label: {
                                Text("+")
                                    .font(.spaceGrotesk(.medium, size: 16))
                                    .foregroundStyle(theme.text)
                                    .frame(width: 28, height: 28)
                                    .background(theme.btnBg, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(theme.sheet.ignoresSafeArea())
        .alert("Export failed", isPresented: exportErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "Unknown error.")
        }
        .alert("Invalid backup file.", isPresented: importErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage ?? "Unknown error.")
        }
        .alert("Delete failed", isPresented: deleteErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "Unknown error.")
        }
        .alert("Replace all data?", isPresented: $showImportConfirm) {
            Button("Replace", role: .destructive) {
                performImport()
            }
            Button("Cancel", role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text("Replace all tasks and projects with this backup?")
        }
        .alert("Delete all data?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                performDeleteAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Permanently remove all tasks and projects? This cannot be undone.")
        }
        .alert("Notifications unavailable", isPresented: notificationDeniedPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(notificationDeniedMessage ?? "Turn on notifications in Settings to get daily reminders.")
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                pendingImportURL = url
                showImportConfirm = true
            case .failure:
                importErrorMessage = "Invalid backup file."
            }
        }
        .sheet(item: exportFileBinding, onDismiss: { exportURL = nil }) { exported in
            ActivityView(activityItems: [exported.url])
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.spaceGrotesk(.bold, size: 18))
                .foregroundStyle(theme.text)

            Spacer()

            Button {
                closeSettings()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.textSub)
                    .frame(width: 30, height: 30)
                    .background(theme.btnBg, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    private func sectionHeader(_ title: String, topPadding: CGFloat) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.spaceGrotesk(.medium, size: 11))
                .tracking(0.8)
                .foregroundStyle(theme.textMuted)
            Spacer()
        }
        .padding(.leading, 4)
        .padding(.top, topPadding)
        .padding(.bottom, 10)
    }

    private var exportErrorPresented: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )
    }

    private var importErrorPresented: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )
    }

    private var deleteErrorPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private var notificationDeniedPresented: Binding<Bool> {
        Binding(
            get: { notificationDeniedMessage != nil },
            set: { if !$0 { notificationDeniedMessage = nil } }
        )
    }

    private var exportFileBinding: Binding<ExportedFile?> {
        Binding(
            get: { exportURL.map(ExportedFile.init(url:)) },
            set: { exportURL = $0?.url }
        )
    }

    private func export() {
        do {
            exportURL = try DataExportHelper.exportData(tasks: tasks, projects: projects)
        } catch {
            exportErrorMessage = String(describing: error)
        }
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }
        pendingImportURL = nil

        do {
            let bundle = try DataImportHelper.decode(from: url)
            try DataImportHelper.replaceAll(bundle: bundle, in: modelContext)
            closeSettings()
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func performDeleteAll() {
        do {
            try DataDeleteHelper.deleteAll(in: modelContext)
            taskDeleteUndo.dismiss()
            closeSettings()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }

    private func closeSettings() {
        dismiss()
    }

    @MainActor
    private func handleNotificationsChange(enabled: Bool) async {
        if enabled {
            let granted = await NotificationScheduler.requestAuthorization()
            guard granted else {
                preferences.notificationsEnabled = false
                notificationDeniedMessage = "Turn on notifications in Settings to get daily reminders."
                return
            }
            await NotificationScheduler.sync(with: preferences)
        } else {
            NotificationScheduler.cancelDailyReminder()
        }
    }
}

private struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL

    init(url: URL) { self.url = url }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsSheetView()
        .environment(AppPreferences())
        .environment(TaskDeleteUndoController())
}
