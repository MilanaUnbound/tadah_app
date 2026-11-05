import Foundation
import OSLog

/// Writes JSON backups on-device (Application Support) using the same format as manual export.
enum LocalAutoBackupHelper {
    private static let logger = Logger(subsystem: "tadah_app", category: "autobackup")
    private static let lastBackupAtKey = "localAutoBackup.lastBackupAt"
    private static let minInterval: TimeInterval = 60
    private static let maxDatedBackups = 7
    private static let latestFileName = "latest.json"

    static var lastBackupDate: Date? {
        UserDefaults.standard.object(forKey: lastBackupAtKey) as? Date
    }

    static var latestBackupURL: URL? {
        let url = backupsDirectoryURL().appendingPathComponent(latestFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Creates/updates the on-device backup. Skips if a backup ran recently unless `force` is true.
    @discardableResult
    static func backupIfNeeded(
        tasks: [Task],
        projects: [Project],
        force: Bool = false
    ) -> Bool {
        if force == false, let last = lastBackupDate,
           Date().timeIntervalSince(last) < minInterval {
            return false
        }

        do {
            try writeBackup(tasks: tasks, projects: projects)
            return true
        } catch {
            logger.error("Auto-backup failed: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    static func formattedLastBackupHint(now: Date = Date()) -> String {
        guard let last = lastBackupDate else {
            return "Automatic backups stay on this device"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: last, relativeTo: now)
        return "Last automatic backup \(relative)"
    }

    private static func writeBackup(tasks: [Task], projects: [Project]) throws {
        let dir = backupsDirectoryURL()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let data = try DataExportHelper.encodeBackupData(tasks: tasks, projects: projects)

        let latest = dir.appendingPathComponent(latestFileName)
        try data.write(to: latest, options: [.atomic])

        let stamped = dir.appendingPathComponent("backup-\(stampFormatter.string(from: Date())).json")
        try data.write(to: stamped, options: [.atomic])

        pruneOldBackups(in: dir)
        UserDefaults.standard.set(Date(), forKey: lastBackupAtKey)
        logger.info("Auto-backup written (\(tasks.count) tasks, \(projects.count) projects)")
    }

    private static func backupsDirectoryURL() -> URL {
        let base: URL
        do {
            base = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        } catch {
            base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
        return base.appendingPathComponent("Backups", isDirectory: true)
    }

    private static func pruneOldBackups(in directory: URL) {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let dated = urls
            .filter { $0.lastPathComponent.hasPrefix("backup-") && $0.pathExtension == "json" }
            .sorted { lhs, rhs in
                let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return l > r
            }

        for url in dated.dropFirst(maxDatedBackups) {
            try? fm.removeItem(at: url)
        }
    }

    private static let stampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
}
