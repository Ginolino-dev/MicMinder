# Release notes

## 1.1.7 — testing release

- Bound Automation-permission waits so an unresponsive macOS permission service cannot indefinitely block the menu or setup checks.
- Show unavailable permission feedback and a System Settings action instead of leaving both players on Checking permission.
- Keep a bounded number of outstanding permission workers and never cache completed authorization results.
- Standalone timeout/recovery regression passed; all 58 XCTest tests subsequently passed on GitHub’s macOS runner with zero failures. The user confirmed playback works after restarting the Mac; this does not establish that MicMinder caused or resolved the macOS service hang.

## 1.1.6

- Reduce locally measured sustained microphone-active CPU from 4.16% to 2.98% of one core; see [performance results](docs/PERFORMANCE.md) for methodology and limits.

- Reuse the compiled paused-player query instead of compiling it on every poll, with at most one cached script per supported player.
- Continue checking current Automation permission and reading fresh playback state on every execution.
- Discard compiled scripts after player restarts or execution errors; prevent reentrant execution.
- Add four real AppleScript regressions for reuse, fresh results, authorization, restart and error handling; all 54 tests pass.

## 1.1.5

- Combine paused-state and track-identity queries during microphone sessions, avoiding redundant Automation permission checks.
- Preserve the quarter-second observation interval, immediate resume checks and existing fade behavior.
- Add a regression for avoiding separate state and identity queries during pause ownership checks; all 50 tests pass.

## 1.1.4

- Audit native playback, permissions, resource use and release packaging.
- Remove unused audio-query helpers, legacy iTunes handling, obsolete UI strings, old screenshots and the retired teal icon generator.
- Cache the English resource bundle instead of resolving it on each status update.
- Include the MIT license in app bundles and validate packaging inputs before building.
- Gate release packaging on tests; label archive architecture and include a checksum.
- Correct source-build requirements and version instructions.

## 1.1.3

- Simplify More Options to Welcome & Setup, Help & Feedback, Release Notes and Quit MicMinder.
- Remove manual Refresh and the language selector; use English consistently, including permission descriptions.

## 1.1.2

- Use an Apple popover anchored to the menu bar icon, with native outside-click and Escape dismissal.
- Simplify the main controls and move language, setup and secondary actions into More Options.
- Retain asynchronous permission refresh, system appearance and native switches.

## 1.1.1

- Open the panel immediately, with permission status refreshed in the background.
- Use native Liquid Glass on macOS 26+ and translucent native material on older versions.
- Follow the system light/dark appearance, with native Apple switches and their standard on/off appearance.
- Add permission-refresh regressions; all 49 tests pass.

## 1.1.0

- Custom music-note and pause symbol for the menu bar and charcoal app icon.
- Compact native panel with switches for automatic control, fades and login launch.
- Inline Apple Music and Spotify switches, with persistent per-player control.
- Redesigned welcome screen using the same player controls.
- Player disable restores an owned fade before relinquishing playback control.
- Spotify volume acknowledgement fix validated manually alongside Apple Music.
- Clarified microphone-triggered call use cases and browser-support limitations.


Version 1.1.6 is the first downloadable testing release, for Apple Silicon Macs. Earlier entries describe development builds. Browser-control experiments are separate from the installed MicMinder app.

## 1.0.3 — 14 October 2026

### Fixed

- Fade-in waits for confirmed playback before starting its half-second timer. A slow Apple Music Play command no longer consumes the fade duration.
- Delayed playback confirmation no longer cancels fade-in immediately.
- Playback and volume callbacks cannot revive a canceled fade or overwrite queued microphone changes with stale timer updates.
- Ending microphone input during a volume write restores the player's original volume safely.

### Verified

- Apple Music pause/resume and fade-out/fade-in confirmed in manual voice-input testing.
- 43 regression tests passed during development verification.

## 1.0.2 — 14 October 2026

### Added

- Optional Fade Music menu control, enabled by default.
- Player-volume fade-out before pausing and fade-in when resuming.
- Restoration of normal player volume while paused, with respect for volume changes made during the pause.
- Recovery of interrupted volume changes when Automation access returns while the app is running.

### Improved

- Playback Permissions window activation and foreground ordering.
- Cleanup when automatic control is disabled or the app quits.

## 1.0.1 — 14 October 2026

### Added

- First-launch welcome flow for connecting Apple Music and Spotify.
- Connected, denied, and unavailable-player feedback, with a link to Automation settings when needed.

### Removed

- Manual Test Media Key control and its Accessibility permission dependency.
- Empty Settings window and unused SwiftUI menu view.

## 1.0.0 — 14 October 2026

### Added

- MicMinder name, teal microphone-and-pause icon, and updated bundle identity.
- Optimized standalone macOS app bundle that can run from Applications independently of the development folder.

### Inherited improvements from this fork

- Confirmed pause ownership and conservative playback restoration.
- Support for delayed Apple Music pause confirmation.
- Optional, dismissible permission setup.
- Event-driven CoreAudio monitoring and fewer unnecessary UI updates and background scans.

## Experimental work

A separate prototype has demonstrated explicit YouTube pause and resume in Chrome without a browser extension. Browser playback control, app exclusions, and website exclusions are **not part of the current installed app**. Prototype results do not establish support for every browser, website, or tab-switching scenario.
