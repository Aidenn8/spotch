import AppKit

// Tiny login agent: opens Spotch whenever Spotify launches. It only reacts
// to macOS's app-launch notifications, so it sits idle the rest of the time.
// Spotch quits itself when Spotify quits.

let spotifyID = "com.spotify.client"

// Lives next to the app's own executable in Spotch.app/Contents/MacOS,
// so the main bundle is the app itself.
let appURL = Bundle.main.bundleURL

func openSpotch() {
    // Already open (e.g. the user just opened it, which re-registers us).
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
    guard !running.contains(where: { $0.executableURL?.lastPathComponent == "Spotch" }) else { return }
    let config = NSWorkspace.OpenConfiguration()
    config.activates = false
    config.addsToRecentItems = false
    config.arguments = ["--watcher"]   // skip the welcome message
    NSWorkspace.shared.openApplication(at: appURL, configuration: config)
}

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main
) { note in
    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    if app?.bundleIdentifier == spotifyID { openSpotch() }
}

if !NSRunningApplication.runningApplications(withBundleIdentifier: spotifyID).isEmpty {
    openSpotch()
}

// A plain run loop rather than NSApplication: an NSApplication here would
// register with macOS as a running copy of Spotch itself (it shares
// the bundle), which would stop the real app from launching.
RunLoop.main.run()
