<p align="center">
  <img src="design/MicMinder-icon.png" alt="MicMinder white music note and pause symbol on charcoal" width="120">
</p>

# MicMinder

**Music makes room for your voice.**

MicMinder is a small macOS menu bar app that automatically pauses your music when the microphone becomes active, then resumes the playback it paused when the microphone becomes idle. Use it for voice input, calls and recording while listening to music. Answer a call on your Mac and let the music make room for the conversation.

[Setup](#get-started) · [Release notes](CHANGELOG.md) · [Build from source](#build-from-source) · [Report an issue](https://github.com/Ginolino-dev/MicMinder/issues)

## What it does

- **Automatic pause and resume:** controls Apple Music and Spotify with explicit player commands.
- **Optional music fades:** aims for a half-second fade-out before pausing and fade-in after playback resumes. Changes the player's volume, not your Mac's system volume.
- **Careful playback restoration:** confirms a pause before owning its resume, and skips resuming if the track or player changes, playback restarts, permission is lost, or automatic control is disabled.
- **Simple setup:** a first-launch welcome window helps connect your player. The same Apple Music and Spotify switches stay available in the menu bar panel.
- **Menu bar controls:** switch Auto Pause/Resume or Fade Music on and off, view microphone activity, and enable Launch at Login.
- **English interface:** English is the supported language for MicMinder.

## Current version and availability

The current version is **1.1.7**, with a compact native Apple popover, adaptive appearance and custom note-and-pause icon. Apple Music and Spotify were retested with the installed 1.1.7 build; playback logs confirmed fade-out, pause, resume and fade-in. All 58 XCTest regression tests passed on GitHub’s macOS runner for 1.1.7. Playback was also manually confirmed after a Mac restart. The full suite runs automatically on pushes and pull requests; local XCTest execution requires the appropriate Apple test tools.

Download **1.1.7 for Apple Silicon Macs (M1 or later)** from [GitHub Releases](https://github.com/Ginolino-dev/MicMinder/releases/tag/v1.1.7). Requires macOS 14 or later. An Intel build is not included.

This initial testing release uses ad hoc signing and is **not Developer ID signed or notarized**. After downloading, unzip it, move MicMinder to Applications, and open it. If macOS blocks it, use **System Settings → Privacy & Security → Open Anyway** after attempting to open it, only if you trust this download. Do not disable Gatekeeper. A SHA-256 checksum is included with the release.

## Performance

In local Apple Music testing, sustained microphone-active CPU averaged **2.98% of one core**, down from 6.72% before the query optimizations. Idle samples returned to 0%. These are measurements on one Mac, not guarantees for every device or player. The optimization preserves fresh permission and playback checks. See the [measurement method and results](docs/PERFORMANCE.md).

## Get started

1. Put `MicMinder.app` in **Applications** and open it.
2. In the welcome window, enable **Apple Music** or **Spotify** and allow macOS's Automation request. Spotify requires its desktop app, available from [Spotify's website](https://www.spotify.com/download/mac/).
3. Play some music, then start and stop microphone input. MicMinder should pause and resume that playback.
4. Use the note-and-pause icon in your menu bar to open the control panel. You can skip setup and connect a player later using its switch.

If you previously denied permission, the player switch opens **System Settings → Privacy & Security → Automation**. Enable the player under MicMinder there.

### Everyday controls

| Control | What it does |
| --- | --- |
| Auto Pause/Resume | Enables automatic playback control. Turning it off cancels any pending resume; already-paused music stays paused until you press Play. |
| Fade Music | Enables player-volume fades around pause and resume. Your volume changes while paused are respected. |
| Apple Music / Spotify | Enables or disables MicMinder control for that player. Switching on requests Automation permission when needed; switching off does not revoke your macOS permission. |
| Launch at Login | Starts the installed app when you log in. |

## Supported behavior and limitations

Microphone detection is system-wide, rather than specific to Codex. Codex voice input has been tested. A colleague has also reported music pausing when answering WhatsApp, FaceTime and iPhone calls on the Mac. These are reported use cases, not a complete compatibility test matrix. Other apps that activate the microphone should trigger the same behavior. The trigger is microphone activation when answering or using a call, rather than the incoming ringtone.

MicMinder detects **microphone use, not speech**. If a meeting app keeps the microphone active, music can remain paused throughout the call. Muting inside an app does not necessarily release the microphone.

- The installed app controls native players. **Browser players are not supported in this version.** A separate Chrome/YouTube prototype has demonstrated pause/resume, but latency and media identity need further validation.
- App exclusions and website exclusions are not implemented.
- Music that was already paused should remain paused. Changing tracks, restarting playback yourself, or disabling automatic control relinquishes the pending resume.
- Track identifiers must be readable; unsupported streams may be skipped. Brief changes between activity checks may not be observable.
- Fade timing depends on how quickly the player responds to automation commands.

## Privacy and permissions

MicMinder observes microphone activity through CoreAudio. It does **not record microphone audio**. The app has no audio capture pipeline or network telemetry.

Playback control needs **Automation permission for each player**. No Accessibility permission is required, and there is no global media-key test. Authorization is requested only when you enable a player in the welcome window or menu bar popover, never silently by background monitoring.

## Build from source

Running the app requires **macOS 14 or later**. Building requires Xcode 26 or later (or equivalent Command Line Tools with the macOS 26+ SDK), because the welcome window uses the Liquid Glass API. The app uses a native material fallback on older macOS versions.

```bash
git clone https://github.com/Ginolino-dev/MicMinder.git
cd MicMinder
BUILD_CONFIGURATION=release APP_VERSION=1.1.7 APP_BUILD_NUMBER=10 ./scripts/build_and_run.sh --package
```

Copy `dist/MicMinder.app` to Applications and open that copy. The bundle contains its executable, icon, and interface resources, so it runs independently of the source checkout and build caches. Enable Launch at Login from the installed copy.

### Development and verification

```bash
swift test
./scripts/build_and_run.sh --verify
```

The packaging script defaults to a debug build. Set `BUILD_CONFIGURATION=release` for an optimized build. Its `--logs`, `--telemetry`, and `--debug` modes support local debugging; `--telemetry` streams local diagnostic logs and does not upload them.

The bundle identifier is `dev.ginolino.MicMinder`. Renaming or moving from HushMic may require fresh Automation authorization.

## Credits and license

MicMinder is a fork of [HushMic by location-txl](https://github.com/location-txl/HushMic), with playback restoration fixes, optional permission setup, event-driven microphone monitoring, a standalone release bundle, new branding, and music fades.

Available under the [MIT License](LICENSE).
