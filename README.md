# You Cannot Sleep

You Cannot Sleep is a small, open-source macOS menu bar utility that keeps a Mac awake for as long as you need. It uses macOS power assertions and has no network access, analytics, or telemetry.

<!-- Screenshot placeholder: add a menu bar screenshot before the first public release. -->

## Features

- One-click menu access with indefinite and timed sessions.
- Prevents idle system sleep and, by default, display sleep.
- Options for screen saver, battery behavior, click behavior, accent color, and a remaining-time indicator.
- Optional launch at login, notifications, and Carbon global shortcut.
- Shortcuts actions, AppleScript commands, and a `youcannotsleep://` URL scheme.
- Runs as a menu bar app without a Dock icon.

Closing a MacBook lid is outside the scope of power assertions. The Mac will enter clamshell sleep when its lid is closed.

## Install

Download `You Cannot Sleep.app` from a release and move it to `/Applications`. CI ad hoc-signs the app with the sandbox and hardened runtime enabled. It is not Developer ID signed or notarized, so Gatekeeper may require approval. Maintainers should configure Developer ID signing and notarization for public distribution.

## Build from source

Open `YouCannotSleep.xcodeproj` in Xcode, or regenerate it from `project.yml` with XcodeGen. Build and run the `YouCannotSleep` scheme. The project targets macOS 13 Ventura and builds a universal arm64/x86_64 binary.

The bundle identifier is `io.github.tarudesu.YouCannotSleep`. The repository and issue links point to [github.com/tarudesu/you-cannot-sleep](https://github.com/tarudesu/you-cannot-sleep).

## Automation

```applescript
tell application "You Cannot Sleep" to toggle
tell application "You Cannot Sleep" to turn on for 30
tell application "You Cannot Sleep" to turn off
tell application "You Cannot Sleep" to get active
```

```sh
open "youcannotsleep://toggle"
open "youcannotsleep://on?minutes=45"
open "youcannotsleep://off"
```

Shortcuts exposes Toggle, Turn On, Turn Off, and Get Status actions.

## Performance

On an Apple Silicon Mac running macOS 27, the universal Release app bundle measured **2.6 MB**. After 1 minute 43 seconds idle, `footprint` reported **20 MB physical footprint (21 MB peak)** and a `ps` sample reported **0.0% CPU**. These are single-machine smoke measurements, not guarantees across hardware or macOS versions. Launch time still needs measurement, and supported versions need hands-on QA before release. The idle implementation uses no polling; session and countdown timers are scheduled only when needed.

Screen saver behavior and power assertions still need hands-on validation on macOS 13–26. By design, default mode requests both `PreventUserIdleDisplaySleep` and `PreventUserIdleSystemSleep`; the “Allow screen saver” option drops the display assertion. No periodic user-activity fallback is enabled until that validation shows it is necessary.

## Privacy

The app makes no network requests and collects or transmits no data. Settings are stored locally in `UserDefaults`. Power assertions are released when the session ends or the app quits.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md), [docs/QA.md](docs/QA.md), and [docs/DECISIONS.md](docs/DECISIONS.md).

Inspired by Caffeinated; not affiliated with Yugen GmbH.
