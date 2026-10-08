# Manual QA checklist

Run this checklist on supported macOS releases (13, 14, 15, and 26) where hardware is available. Record OS version and Mac model with results.

## Power and lifecycle

- [ ] While active, `pmset -g assertions` shows the expected system and display assertions.
- [ ] While inactive and after quitting, no assertion owned by You Cannot Sleep remains.
- [ ] Set display sleep and screen saver to 1 minute: default active mode keeps the display awake and prevents the screen saver from starting.
- [ ] With “Allow screen saver” enabled, the screen saver starts at its normal idle time while the system remains awake.
- [ ] Confirm timed sessions end at their absolute end date after sleep and after a system clock change.
- [ ] Confirm a lid close still causes expected clamshell sleep.
- [ ] Confirm screen lock and fast user switching preserve the session without a crash.
- [ ] Launch a second copy: the new process exits and the first remains active.
- [ ] Quit while active and verify assertions are released synchronously.

## Menu and windows

- [ ] Choose each timed duration button and the standalone Indefinitely button; confirm activation or restart, selection feedback, and countdown updates. Confirm More durations contains only finite presets and Custom opens the duration editor.
- [ ] Check the original lighthouse app icon and the custom menu bar glyph in light/dark appearances, active/inactive states, and with accent coloring enabled.
- [ ] Left-click, right-click, and Control-click route correctly with both click behavior settings.
- [ ] Repeat on built-in and external displays, including a multi-display arrangement.
- [ ] Confirm the status item remains accessible with VoiceOver and the countdown is stable in width.
- [ ] Confirm the panel header refreshes while open, timers stop after it closes, and clicking outside or pressing Escape dismisses it.
- [ ] Use keyboard focus and Return to activate buttons; verify VoiceOver announces duration names and selected state.
- [ ] Expand Options, scroll to every toggle, and confirm the footer remains accessible on small screens.
- [ ] Check Settings, Welcome, About, and custom duration window focus and single-instance behavior.
- [ ] Enable “Group windows by application” in Mission Control and confirm there is no empty window.
- [ ] Check Light mode, Dark mode, accent color updates, and Retina/non-Retina displays.

## Power source and notifications

- [ ] On a Mac with a battery, test AC-to-battery shutoff and battery threshold hysteresis.
- [ ] Verify charger-connect activation occurs only after a real battery-to-AC transition, not on app launch.
- [ ] Verify manual activation on battery takes precedence until the next power-source transition.
- [ ] Test notifications with permission allowed, denied, and not yet requested.
- [ ] Confirm battery options are hidden on a desktop Mac.

## Automation and distribution

- [ ] Register and use the global shortcut; test a conflicting shortcut and clear behavior.
- [ ] Run all four Shortcuts actions and verify status includes active state and remaining minutes.
- [ ] Run all AppleScript examples from Script Editor, including application properties.
- [ ] Run `open "youcannotsleep://toggle"`, `open "youcannotsleep://on?minutes=45"`, and `open "youcannotsleep://off"`.
- [ ] Verify launch at login survives reboot and reflects Login Items approval status.
- [ ] Verify `You Cannot Sleep.app` works with its display name and spaces in Login Items, AppleScript, and Shortcuts.
- [ ] Measure launch-to-status-item time and repeat CPU/RAM measurements on supported macOS releases before distribution.

## Recorded smoke run

**2026-10-08 · Apple Silicon · macOS 27 · Xcode 27**

- Universal Release build succeeded for arm64 and x86_64 with no compiler warnings. The app bundle measured 2.6 MB.
- The unit test suite passed: 15 tests, zero failures.
- `pmset -g assertions` showed both expected assertions during an awake session. After the app quit, no assertion owned by You Cannot Sleep remained.
- URL activation with a timed session and AppleScript status, on, off, and toggle commands were exercised. URL commands did not open a window.
- After 1 minute 43 seconds in an active session with no UI interaction, `footprint` reported 20 MB physical footprint (21 MB peak), and a `ps` sample reported 0.0% CPU.
- A Time Profiler trace was captured. The Allocations recording did not complete on this host, so the footprint measurement above came from `footprint` instead.

The one-minute display/screen-saver checks, launch timing, and hardware interaction checklist remain outstanding. This host runs macOS 27, so the macOS 13, 14, 15, and 26 runs also remain outstanding.
