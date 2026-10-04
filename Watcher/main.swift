import AppKit

// Tiny login agent: opens Spotch whenever Spotify launches. It only reacts
// to macOS's app-launch notifications, so it sits idle the rest of the time.
// Spotch quits itself when Spotify quits.

let spotifyID = "com.spotify.client"

// Installed at Spotch.app/Contents/Helpers/SpotchWatcher.
let appURL = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
    .deletingLastPathComponent()   // Helpers
    .deletingLastPathComponent()   // Contents
    .deletingLastPathComponent()   // Spotch.app

func openSpotch() {
    let config = NSWorkspace.OpenConfiguration()
    config.activates = false
    config.addsToRecentItems = false
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

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
