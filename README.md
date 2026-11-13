# Spotch

[![CI](https://github.com/Aidenn8/spotch/actions/workflows/ci.yml/badge.svg)](https://github.com/Aidenn8/spotch/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/Aidenn8/spotch)](https://github.com/Aidenn8/spotch/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.10-F05138?logo=swift&logoColor=white)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Turns the notch on your MacBook into a now-playing widget: the notch shows
what's playing in the Spotify desktop app, and grows into a mini player when
you hover over it.

<p align="center">
  <a href="docs/media/demo-full-screen.mp4"><img src="docs/media/demo-full-screen.gif" width="640" alt="The widget sits in the notch with the album cover and a visualizer. Hovering opens a mini player; skipping to the next song changes the cover and accent color, and time-synced lyrics appear in the panel. The panel closes and the view pulls back to show the whole MacBook screen."></a>
</p>

<p align="center">
  <b><a href="#install">Install in one step</a></b>
  · free · macOS 14+ on a MacBook with a notch
</p>

## Features

- **Closed:** the notch extends slightly to each side, with the album cover on
  the left and a pulsing visualizer on the right.
- **Open:** hover over it and it grows into a mini player with the cover, song,
  progress bar, and shuffle / previous / play-pause / next / repeat buttons.
- Colors are picked from the album cover.
- Pick the open panel's background: solid black (default) or one of four glass
  styles (smoky, frosted, clear, or tinted with the album's color).
- Optional time-synced lyrics in the open panel, scrolling up line by line
  (off by default).
- It appears when Spotify opens and disappears when Spotify quits, and keeps
  doing so after you restart your Mac, with nothing to set up again.

<table>
  <tr>
    <td width="50%"><img src="docs/media/expanded.png" alt="The open panel: cover, song and artist, visualizer, progress bar and playback controls."></td>
    <td width="50%"><img src="docs/media/lyrics.png" alt="The open panel with two lines of time-synced lyrics between the song and the progress bar."></td>
  </tr>
  <tr>
    <td align="center"><sub>Hover to open</sub></td>
    <td align="center"><sub>With lyrics turned on</sub></td>
  </tr>
</table>

## Install

You need a MacBook with a notch (Apple Silicon) on macOS 14 Sonoma or later,
and the Spotify app.

Open **Terminal** (in Applications → Utilities), paste this line and press
Return:

```sh
curl -fsSL https://raw.githubusercontent.com/Aidenn8/spotch/main/get.sh | bash
```

That's it. It downloads the latest release, puts Spotch in your Applications
folder, sets it up and opens Spotify, and the widget appears as soon as a song
plays. When macOS asks whether Spotch can control Spotify, click **OK**.

There's no download to save, no "suspicious download" warning from your browser
and no "Apple could not verify" step: those only come up for files downloaded
in a browser. [`get.sh`](get.sh) is short if you'd like to read it first.

<details>
<summary>Prefer a disk image? (it comes with extra warnings)</summary>

Spotch isn't notarized by Apple, so downloading the disk image in a browser
brings up warnings that the line above avoids: your browser may call it a
suspicious download (choose **Keep**), and macOS makes you approve it once.

**[⬇ Download Spotch.dmg](https://github.com/Aidenn8/spotch/releases/latest/download/Spotch.dmg)**, then:

1. Open the downloaded **Spotch.dmg**.
2. Drag **Spotch** into the **Applications** folder.
3. Open **Spotch** from your Applications folder. Playing music in Spotify
   isn't enough: Spotch has to be opened once to set itself up.
4. macOS will warn that it can't check the app for malicious software. That's
   because this is a free project that isn't registered with Apple. To allow it,
   this one time:
   - Click **Done** (or **OK**) on the warning.
   - Open **System Settings → Privacy & Security**.
   - Scroll down to the message about Spotch and click **Open Anyway**,
     then confirm with your password.
5. Spotify opens and the widget appears in the notch. When macOS asks whether
   Spotch can control Spotify, click **OK**.

</details>

### Uninstall

Drag **Spotch** from your Applications folder to the Trash. It removes
its login item by itself, so nothing is left behind.

### Updating

Run the install line again. If you installed from the disk image, download the
new version, drag it into Applications (replace the old one), and open it once.

Coming from version 1.2.1 or earlier? Open the new version once: it switches
off the old copy, which you can then drag to the Trash.

## Tips

- If the widget never shows up, open **System Settings → General → Login
  Items** and make sure Spotch is allowed in the background, then run the
  install line again.
- Right-click the widget to change the background, turn lyrics on or off, open
  Spotify, or quit. After quitting, it comes back the next time Spotify opens.
- Lyrics come from [LRCLIB](https://lrclib.net), a free community lyrics
  database. While lyrics are on, the song's title and artist are sent there to
  look them up. Instrumentals and many covers have none, and then the panel
  looks as usual.
- Shuffle and repeat only work when music is playing on this Mac. If Spotify is
  controlling another device (for example "Playing on iPhone"), those two
  buttons can't change it.

## How it works

Written in Swift (AppKit + SwiftUI), about 1,900 lines with no dependencies.

```mermaid
flowchart LR
    spotify["Spotify app"]
    watcher["Login agent<br/>(Watcher)"]
    model["PlayerModel<br/>playback state"]
    lyrics["LyricsModel<br/>synced lyrics"]
    lrclib[("LRCLIB")]
    controller["NotchController<br/>window, hover, mode"]
    view["NotchView<br/>SwiftUI"]

    watcher -- "opens the widget<br/>when Spotify launches" --> controller
    spotify -- "notification on<br/>every change" --> model
    model -- "AppleScript: cover,<br/>shuffle, repeat, commands" --> spotify
    model --> lyrics
    lyrics -- "on track change" --> lrclib
    model --> view
    lyrics --> view
    controller --> view
```

- **Playback state** comes from the notification Spotify posts whenever
  playback changes, so nothing is polled. Cover art, shuffle and repeat are read
  with one AppleScript call per change.
- **The visualizer** is a Core Animation loop that runs in the window server,
  capped at 30 fps, so the app uses no CPU while music plays. It's a stylized
  animation, not real audio levels. In `top` the app sits at 0.0% CPU and
  about 20 MB of memory.
- **Animating the notch:** the window is only ever as big as the current shape,
  so it never blocks clicks on the menu bar. To change shape, it first grows to
  fit both the old and new shapes, SwiftUI springs between them, and the window
  is trimmed afterwards. The SwiftUI view stays pinned at its largest size the
  whole time, so resizing the window can't shift it (an early version slid in
  from the left when it opened).
- **Staying on the notch** uses private CoreGraphics/SkyLight calls to put the
  window in its own space above the desktops, so it doesn't slide when you
  switch Spaces (`Sources/StickySpace.swift`).
- **Lyrics** are fetched from LRCLIB when the song changes and timed against
  Spotify's playback position, with one timer for the next line rather than
  polling. The timers only run while the panel is open.
- **Opening with Spotify:** when you open the app it installs a small login
  agent (`Watcher/main.swift`) that waits for Spotify to launch and opens the
  widget. The widget quits when Spotify does. When the app is moved to the
  Trash, the agent removes itself.

### Project layout

```
Sources/
  main.swift              app entry: setup, one copy at a time, launch flags
  NotchController.swift   the panel window, hover handling, mode changes
  NotchView.swift         the SwiftUI widget: closed and open layouts, controls
  NotchGeometry.swift     notch detection, sizes for each mode, the notch shape
  Player.swift            playback state, Spotify commands, accent color from the cover
  Lyrics.swift            LRCLIB lookup, LRC parsing, line timing, the lyrics scroller
  Visualizer.swift        the Core Animation bars
  PanelStyle.swift        solid and glass backgrounds
  StickySpace.swift       private SkyLight calls that keep the window above Spaces
  Installer.swift         the login agent: setup and self-removal
  Demo.swift              made-up songs for --demo and the recording below
Watcher/main.swift        login agent that opens the widget when Spotify launches
Tests/                    XCTest: geometry, LRC parsing, lyric timing, accent colors
tools/record-demo/        renders the widget off-screen and records docs/media
tools/make-icon.swift     draws the app icon
```

## Build from source

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/Aidenn8/spotch.git
cd spotch
./install.sh      # build, copy to ~/Applications and set up
./uninstall.sh    # remove it again
```

`./build.sh` builds into `build/` without installing, and `./package.sh` makes
`dist/Spotch.dmg`. `swift test` runs the tests (this needs Xcode), and
`open Package.swift` opens the project in Xcode.

Launch flags for development: `--demo` plays made-up songs without Spotify,
`--expanded` pins the panel open. `./tools/record-demo.sh` re-records the GIF,
video and screenshots in `docs/media`: it renders the real widget in an
off-screen window, plays a scripted hover, and captures every frame, so nothing
appears on screen while it runs. `tools/make-icon.swift` redraws the app icon.

## Known limitations

- Shuffle and repeat use Spotify's AppleScript interface, which can't reach
  other devices over Spotify Connect, and doesn't support Smart Shuffle or
  repeat-one.
- The private APIs used to stay fixed during Space switches are undocumented
  and could change in a future macOS release.
- The app isn't notarized by Apple, so the disk image download comes with
  browser and macOS warnings. The one-line install avoids them.

## License

[MIT](LICENSE). Spotch is an independent project and isn't affiliated with,
sponsored or endorsed by Spotify. Spotify is a trademark of Spotify AB, used
here only to say which app Spotch works with. Spotch talks to the Spotify
desktop app through the AppleScript interface macOS provides; it doesn't use
Spotify's web API, and this repository contains no Spotify code or logos.
