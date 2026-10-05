import AppKit

// Tiny login agent: opens Spotch whenever Spotify launches. It only reacts
// to macOS's app-launch notifications, so it sits idle the rest of the time.
// Spotch quits itself when Spotify quits. Dragging the app to the Trash
// uninstalls it: this agent then removes itself.

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
    config.arguments = ["--watcher"]   // skip setup
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

// Uninstalling is dragging the app to the Trash. macOS reports the moment the
// bundle is moved or deleted; then remove this login agent so nothing is left
// behind. (If the app was only moved, opening it again sets it back up.)
let label = "com.aidenn8.spotch.watcher"
let bundleFile = open(appURL.path, O_EVTONLY)
let bundleWatch = DispatchSource.makeFileSystemObjectSource(fileDescriptor: bundleFile,
                                                            eventMask: [.rename, .delete], queue: .main)
bundleWatch.setEventHandler {
    let plist = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    try? FileManager.default.removeItem(at: plist)
    // Unloading the agent ends this process.
    let launchctl = Process()
    launchctl.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    launchctl.arguments = ["bootout", "gui/\(getuid())/\(label)"]
    try? launchctl.run()
    launchctl.waitUntilExit()
    exit(0)
}
bundleWatch.resume()

// A plain run loop rather than NSApplication: an NSApplication here would
// register with macOS as a running copy of Spotch itself (it shares
// the bundle), which would stop the real app from launching.
RunLoop.main.run()
