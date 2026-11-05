import SwiftUI
import SwiftData
import OSLog
import UIKit

@main
struct adhd_todoApp: App {
    @StateObject private var loader = SwiftDataContainerLoader()
    @State private var preferences = AppPreferences()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = loader.container {
                    ContentView()
                        .modelContainer(container)
                        .environment(preferences)
                        .preferredColorScheme(preferences.resolvedColorScheme)
                        .withAppTheme()
                        .task {
                            await NotificationScheduler.sync(with: preferences)
                        }
                } else if let error = loader.loadError {
                    StoreLoadFailureView(
                        error: error,
                        onContinueWithoutData: { loader.continueWithoutData() }
                    )
                } else {
                    LoadingScreenView()
                        .withAppTheme()
                        .task { loader.load() }
                }
            }
        }
    }
}

private struct LoadingScreenView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            Image("LaunchFace")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
        }
    }
}

@MainActor
private final class SwiftDataContainerLoader: ObservableObject {
    @Published var container: ModelContainer?
    @Published var loadError: Error?

    private let logger = Logger(subsystem: "tadah_app", category: "swiftdata")

    func load() {
        guard container == nil, loadError == nil else { return }

        let url = Self.storeURL()
        let config = ModelConfiguration(url: url)

        do {
            container = try ModelContainer(for: Task.self, Project.self, configurations: config)
            logger.info("SwiftData container loaded. url=\(url.absoluteString, privacy: .private)")
        } catch {
            #if DEBUG
            // DEBUG/DEVELOPMENT ONLY:
            // If the store fails to open (often schema mismatch during development), it's acceptable
            // to wipe-and-recreate so iteration isn't blocked. NEVER do this in production builds.
            logger.error("SwiftData failed to load (DEBUG). Wiping store and retrying. url=\(url.absoluteString, privacy: .private) error=\(String(describing: error), privacy: .public)")
            try? FileManager.default.removeItem(at: url)
            do {
                container = try ModelContainer(for: Task.self, Project.self, configurations: config)
                logger.info("SwiftData container loaded after wipe (DEBUG). url=\(url.absoluteString, privacy: .private)")
            } catch {
                loadError = error
                logger.error("SwiftData failed to load after wipe (DEBUG). url=\(url.absoluteString, privacy: .private) error=\(String(describing: error), privacy: .public)")
            }
            #else
            // PRODUCTION/RELEASE:
            // Never delete user data. Surface a blocking recovery UI instead.
            loadError = error
            logger.error("SwiftData failed to load (RELEASE). url=\(url.absoluteString, privacy: .private) error=\(String(describing: error), privacy: .public)")
            #endif
        }
    }

    func continueWithoutData() {
        logger.error("User chose ContinueWithoutData (in-memory SwiftData).")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: Task.self, Project.self, configurations: config)
            loadError = nil
        } catch {
            loadError = error
            logger.error("Failed to create in-memory SwiftData container. error=\(String(describing: error), privacy: .public)")
        }
    }

    private static func storeURL() -> URL {
        do {
            let base = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return base.appendingPathComponent("Tadah.store")
        } catch {
            return URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("Tadah.store")
        }
    }
}

private struct StoreLoadFailureView: View {
    let error: Error
    let onContinueWithoutData: () -> Void

    @State private var showingDetails = false
    @State private var shareBackupURL: URL?

    private var latestBackupURL: URL? {
        LocalAutoBackupHelper.latestBackupURL
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 10) {
                Text("We couldn’t open your data")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("Your data is still on your device. The app couldn’t read it right now.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Try:")
                        .font(.subheadline.weight(.semibold))
                    Text("• Force quit and reopen the app")
                    Text("• Restart your phone")
                    Text("• Make sure you’re on the latest version")
                    Text("• Contact support and include the error details below")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .frame(maxWidth: 420, alignment: .leading)
            }

            VStack(spacing: 10) {
                if let latestBackupURL {
                    Button {
                        shareBackupURL = latestBackupURL
                    } label: {
                        Text("Share last automatic backup")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    showingDetails.toggle()
                } label: {
                    Text(showingDetails ? "Hide error details" : "Show error details")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)

                if showingDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(errorText)
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            Button("Copy details") {
                                copyToPasteboard(errorText)
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 16)
                    .frame(maxWidth: 520)
                }

                Button(role: .destructive) {
                    onContinueWithoutData()
                } label: {
                    Text("Continue without data")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Text("This will open the app with an empty database for this session only.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .sheet(item: shareBackupBinding) { item in
            RecoveryShareSheet(activityItems: [item.url])
                .ignoresSafeArea()
        }
    }

    private var shareBackupBinding: Binding<ShareableBackup?> {
        Binding(
            get: { shareBackupURL.map(ShareableBackup.init(url:)) },
            set: { shareBackupURL = $0?.url }
        )
    }

    private var errorText: String {
        String(describing: error)
    }

    private func copyToPasteboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}

private struct ShareableBackup: Identifiable {
    let id = UUID()
    let url: URL
}

private struct RecoveryShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
