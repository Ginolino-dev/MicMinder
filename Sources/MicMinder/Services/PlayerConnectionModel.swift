import AppKit
import Combine

final class PlayerConnectionModel: ObservableObject {
  struct Status: Equatable {
    var authorized: Bool
    var enabled: Bool
    var denied: Bool
    var unavailable: Bool = false
  }
  @Published private(set) var statuses: [String: Status] = [:]
  @Published private(set) var requesting: String?
  @Published private(set) var errorMessage: String?
  @Published private(set) var isRefreshing = false
  private let permissionQueue = DispatchQueue(label: "dev.ginolino.MicMinder.permissions", qos: .userInitiated)
  private var timer: Timer?
  private var observers = 0
  private let appModel: AppModel
  private let query: (ScriptableMediaPlayer) -> (authorized: Bool, denied: Bool, unavailable: Bool)
  init(appModel: AppModel, query: @escaping (ScriptableMediaPlayer) -> (authorized: Bool, denied: Bool, unavailable: Bool) = { PermissionAuthorizationService.connectionStatus(for: $0) }) {
    self.appModel = appModel; self.query = query
  }
  func start() {
    observers += 1; refresh()
    guard timer == nil else { return }
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.refresh() }
  }
  func stop() {
    observers = max(0, observers - 1)
    if observers == 0 { timer?.invalidate(); timer = nil }
  }
  func refresh() {
    guard !isRefreshing else { return }
    isRefreshing = true
    let query = self.query
    permissionQueue.async { [weak self] in
      var updated: [String: Status] = [:]
      for player in PermissionAuthorizationService.setupPlayers {
        let result = query(player)
        updated[player.bundleIdentifier] = Status(authorized: result.authorized, enabled: true, denied: result.denied, unavailable: result.unavailable)
      }
      DispatchQueue.main.async {
        guard let self else { return }
        for identifier in updated.keys {
          updated[identifier]?.enabled = PlayerControlSettings.shared.isEnabled(identifier)
        }
        if updated != self.statuses { self.statuses = updated }
        self.isRefreshing = false
      }
    }
  }
  private func updateSetting(_ enabled: Bool, player: ScriptableMediaPlayer) {
    PlayerControlSettings.shared.setEnabled(enabled, for: player.bundleIdentifier)
    if var status = statuses[player.bundleIdentifier] {
      status.enabled = enabled
      statuses[player.bundleIdentifier] = status
    }
  }
  func setEnabled(_ enabled: Bool, player: ScriptableMediaPlayer) {
    errorMessage = nil
    if !enabled {
      appModel.prepareToDisablePlayer(player)
      updateSetting(false, player: player)
      appModel.refresh(); refresh(); return
    }
    if statuses[player.bundleIdentifier]?.authorized == true {
      updateSetting(true, player: player)
      appModel.refresh(); refresh(); return
    }
    if statuses[player.bundleIdentifier]?.unavailable == true {
      errorMessage = "macOS isn’t answering permission checks. Check Automation in System Settings. If this persists, restart your Mac and reopen MicMinder."
      PermissionAuthorizationService.openSettings(); return
    }
    if statuses[player.bundleIdentifier]?.denied == true {
      PermissionAuthorizationService.openSettings(); return
    }
    requesting = player.bundleIdentifier
    let authorize = { [weak self] in
      DispatchQueue.global(qos: .userInitiated).async {
        let granted = PermissionAuthorizationService.requestAutomationPermission(for: player)
        DispatchQueue.main.async {
          guard let self else { return }
          self.updateSetting(granted, player: player)
          self.requesting = nil
          if !granted { self.errorMessage = "Permission wasn’t confirmed. Check System Settings; if you just allowed access, wait for the connection status to refresh." }
          self.appModel.refresh(); self.refresh()
        }
      }
    }
    if player.isRunning { authorize(); return }
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: player.bundleIdentifier) else {
      requesting = nil; errorMessage = "Install \(player.displayName) to connect it."; return
    }
    let configuration = NSWorkspace.OpenConfiguration(); configuration.activates = false
    NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] _, error in
      DispatchQueue.main.async {
        if error != nil { self?.requesting = nil; self?.errorMessage = "Couldn’t open \(player.displayName)." }
        else { authorize() }
      }
    }
  }
}
