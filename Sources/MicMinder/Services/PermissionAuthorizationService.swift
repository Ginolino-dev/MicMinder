import AppKit
import CoreServices
import Foundation

final class PermissionAuthorizationService {
  private static let checks = BoundedPermissionCheck()
  static let setupPlayers = ScriptableMediaPlayer.supportedPlayers

  static func connectionStatus(for player: ScriptableMediaPlayer) -> (authorized: Bool, denied: Bool, unavailable: Bool) {
    let status = automationPermissionStatus(for: player, askUserIfNeeded: false)
    return (status == noErr, status == OSStatus(errAEEventNotPermitted), status == OSStatus(errAETimeout))
  }

  static func hasAutomationPermission(for player: ScriptableMediaPlayer) -> Bool {
    automationPermissionStatus(for: player, askUserIfNeeded: false) == noErr
  }

  @discardableResult
  static func requestAutomationPermission(for player: ScriptableMediaPlayer) -> Bool {
    automationPermissionStatus(for: player, askUserIfNeeded: true) == noErr
  }

  static func openSettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
      NSWorkspace.shared.open(url)
    }
  }

  private static func automationPermissionStatus(
    for player: ScriptableMediaPlayer, askUserIfNeeded: Bool
  ) -> OSStatus {
    guard player.isRunning else { return OSStatus(procNotFound) }
    // Never let a stuck system permission service indefinitely block playback
    // or setup. Explicit consent gets longer for the user to answer the prompt.
    let key = player.bundleIdentifier + (askUserIfNeeded ? ".request" : ".check")
    return checks.run(key: key, timeout: askUserIfNeeded ? 30 : 0.25) {
      let descriptor = NSAppleEventDescriptor(bundleIdentifier: player.bundleIdentifier)
      guard let target = descriptor.aeDesc else { return OSStatus(errAEEventNotPermitted) }
      return AEDeterminePermissionToAutomateTarget(target, typeWildCard, typeWildCard, askUserIfNeeded)
    } ?? OSStatus(errAETimeout)
  }
}
