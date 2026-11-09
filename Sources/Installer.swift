import AppKit

/// Sets up and removes the login agent that opens the app whenever Spotify
/// launches: a small plist in ~/Library/LaunchAgents pointing at the watcher
/// inside this copy of the app.
///
/// (SMAppService would be the modern route, but with an ad-hoc signed app it
/// breaks after every update, since the recorded signature no longer
/// matches, and it can resolve the helper through stale copies such as the
/// ejected disk image.)
enum Installer {
    static let agentLabel = "com.aidenn8.spotch.watcher"

    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(agentLabel).plist")
    }

    private static var watcherURL: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/SpotchWatcher")
    }

    /// The agent points into the bundle, so the app has to run from a stable
    /// place: not straight from the disk image, and not from the randomized
    /// path macOS uses for apps opened without being moved out of Downloads.
    static var isInStableLocation: Bool {
        let path = Bundle.main.bundlePath
        return !path.contains("/AppTranslocation/") && !path.hasPrefix("/Volumes/")
    }

    /// Called whenever the app is opened by hand. Rewrites and reloads the
    /// agent every time, so it follows the app if it's moved or updated.
    static func install() {
        retireEarlierCopies()
        clearWatcherQuarantine()
        let agent: [String: Any] = [
            "Label": agentLabel,
            "ProgramArguments": [watcherURL.path],
            "RunAtLoad": true,
            "LimitLoadToSessionType": "Aqua",
        ]
        do {
            try FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: agent, format: .xml, options: 0)
            try data.write(to: plistURL, options: .atomic)
        } catch {
            NSLog("Spotch: couldn't write the login agent: \(error)")
            return
        }
        launchctl("bootout", "gui/\(getuid())/\(agentLabel)")
        launchctl("bootstrap", "gui/\(getuid())", plistURL.path)
    }

    static func uninstall() {
        launchctl("bootout", "gui/\(getuid())/\(agentLabel)")
        try? FileManager.default.removeItem(at: plistURL)
    }

    /// Versions before 1.3 had a different bundle identifier, so their login
    /// agent has another label and would keep opening the old copy next to
    /// this one. Remove any such agent and quit the copy it belongs to.
    private static func retireEarlierCopies() {
        let folder = plistURL.deletingLastPathComponent()
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            let name = file.lastPathComponent
            guard name.hasPrefix("com.aidenn8."), name.hasSuffix(".watcher.plist"),
                  name != plistURL.lastPathComponent,
                  let data = try? Data(contentsOf: file),
                  let agent = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let label = agent["Label"] as? String,
                  let watcher = (agent["ProgramArguments"] as? [String])?.first
            else { continue }
            launchctl("bootout", "gui/\(getuid())/\(label)")
            try? FileManager.default.removeItem(at: file)
            // The watcher sits in <app>.app/Contents/MacOS.
            let app = URL(fileURLWithPath: watcher).deletingLastPathComponent()
                .deletingLastPathComponent().deletingLastPathComponent().standardizedFileURL
            guard app.pathExtension == "app", app != Bundle.main.bundleURL.standardizedFileURL else { continue }
            for running in NSWorkspace.shared.runningApplications
            where running.bundleURL?.standardizedFileURL == app {
                running.terminate()
            }
        }
    }

    private static func launchctl(_ arguments: String...) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }

    /// The user has already approved the app itself, but the watcher is
    /// started by launchd rather than Finder and would otherwise be blocked
    /// by the download quarantine flag.
    private static func clearWatcherQuarantine() {
        removexattr(watcherURL.path, "com.apple.quarantine", 0)
    }
}
