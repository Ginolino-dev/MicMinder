import SwiftUI

struct PlayerSwitchRows: View {
  @ObservedObject var connections: PlayerConnectionModel
  var body: some View {
    VStack(spacing: 16) {
      ForEach(PermissionAuthorizationService.setupPlayers, id: \.bundleIdentifier) { player in
        let status = connections.statuses[player.bundleIdentifier]
        HStack {
          VStack(alignment: .leading, spacing: 3) {
            Text(player.bundleIdentifier == "com.apple.Music" ? "Apple Music" : "Spotify").font(.system(size: 13, weight: .medium))
            Text(status == nil ? "Checking permission…" : connections.requesting == player.bundleIdentifier ? "Connecting…" : status?.unavailable == true ? "macOS isn’t responding · opens System Settings" : status?.denied == true ? "Permission needed · opens System Settings" : status?.authorized == true ? (status?.enabled == true ? "Connected" : "Control off") : "Enable playback control")
              .font(.system(size: 11)).foregroundStyle(.secondary)
          }
          Spacer(minLength: 12)
          Toggle(player.displayName, isOn: Binding(
            get: { status?.enabled == true && status?.authorized == true },
            set: { connections.setEnabled($0, player: player) }
          ))
          .labelsHidden().toggleStyle(.switch).disabled(connections.requesting != nil || status == nil)
          .accessibilityLabel((player.bundleIdentifier == "com.apple.Music" ? "Apple Music" : "Spotify") + " playback control")
        }

      }
      if let error = connections.errorMessage {
        Text(error).font(.system(size: 11)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

struct ControlPanelView: View {
  @ObservedObject var model: AppModel
  @ObservedObject var localizer: AppLocalizer
  @ObservedObject var connections: PlayerConnectionModel
  let setup: () -> Void
  let close: () -> Void
  let quit: () -> Void
  private func settingSwitch(_ title: String, value: Binding<Bool>) -> some View {
    HStack {
      Text(title)
      Spacer()
      Toggle(title, isOn: value).labelsHidden().toggleStyle(.switch).accessibilityLabel(title)
    }
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        Image(nsImage: MicMinderSymbol.image(size: 22)).renderingMode(.template)
        VStack(alignment: .leading, spacing: 3) {
          Text("MicMinder").font(.system(size: 17, weight: .semibold))
        }
        Spacer()
      }
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 7) {
          Circle().fill(model.snapshot.isActive ? Color.primary : Color.gray).frame(width: 6, height: 6)
          Text(model.statusTitle(localizer: localizer)).font(.system(size: 12, weight: .medium))
        }
        Text(model.lastActionTitle(localizer: localizer)).font(.system(size: 11)).foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading).padding(12)
      .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
      .help(model.deviceTitle(localizer: localizer))
      VStack(spacing: 14) {
        settingSwitch(localizer.text("menu.auto_control"), value: $model.autoControlEnabled)
        settingSwitch(localizer.text("menu.fade_music"), value: $model.fadeMusicEnabled)
        settingSwitch(localizer.text("menu.launch_at_login"), value: $model.launchAtLoginEnabled)
      }.toggleStyle(.switch).font(.system(size: 13))
      Divider()
      Text("PLAYBACK APPS").font(.system(size: 10, weight: .semibold)).tracking(1).foregroundStyle(.secondary)
      PlayerSwitchRows(connections: connections)
      Divider()
      HStack {
        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")")
          .font(.system(size: 10)).foregroundStyle(.secondary)
        Spacer()
        Menu {
          Button("Welcome & Setup…", action: setup)
          Button("Help & Feedback…") { NSWorkspace.shared.open(URL(string: "https://github.com/Ginolino-dev/MicMinder")!) }
          Button("Release Notes…") { NSWorkspace.shared.open(URL(string: "https://github.com/Ginolino-dev/MicMinder/blob/main/CHANGELOG.md")!) }
          Divider()
          Button("Quit MicMinder", action: quit)
        } label: {
          Image(systemName: "ellipsis.circle").font(.system(size: 16))
        }
        .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("More options")
      }

    }
    .padding(18).frame(width: 320)
    .onExitCommand(perform: close)
  }
}

struct WelcomeView: View {
  @ObservedObject var connections: PlayerConnectionModel
  let finish: () -> Void
  var body: some View {
    VStack(spacing: 22) {
      Image(nsImage: MicMinderSymbol.image(size: 62)).renderingMode(.template)
        .frame(width: 96, height: 96).background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
      VStack(spacing: 10) {
        Text("Music makes room\nfor your voice.").font(.system(size: 30, weight: .semibold)).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        Text("MicMinder pauses your music when your microphone is in use, then resumes the playback it paused.")
          .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        Text("For voice input, calls and recording on your Mac.").font(.system(size: 12)).foregroundStyle(.secondary)
      }
      VStack(alignment: .leading, spacing: 16) {
        Text("Choose your music apps").font(.system(size: 14, weight: .semibold))
        PlayerSwitchRows(connections: connections)
      }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
      Text("macOS will ask before MicMinder controls a player.\nMicMinder observes microphone activity; it never records audio.")
        .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
      Button(action: finish) { Text("Start using MicMinder").font(.system(size: 13, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 9) }
        .buttonStyle(.borderedProminent)
      Text("You can change these switches from the menu bar anytime.").font(.system(size: 10)).foregroundStyle(.secondary)
    }
    .padding(30).frame(width: 480)
  }
}
