import XCTest
@testable import MicMinder
@MainActor
final class PlayerConnectionModelTests: XCTestCase {
  func testUnavailablePermissionIsPublishedInsteadOfCheckingForever() async throws {
    let app = AppModel(microphoneMonitor: SilentMonitor())
    defer { app.prepareForTermination() }
    let model = PlayerConnectionModel(appModel: app, query: { _ in (false, false, true) })
    model.refresh()
    for _ in 0..<100 where model.isRefreshing {
      try await Task.sleep(nanoseconds: 10_000_000)
    }
    XCTAssertFalse(model.isRefreshing)
    XCTAssertEqual(model.statuses["com.apple.Music"]?.unavailable, true)
    XCTAssertEqual(model.statuses["com.spotify.client"]?.authorized, false)
  }

  func testCreatingPanelModelDoesNotQueryPermissions() {
    let app = AppModel(microphoneMonitor: SilentMonitor())
    defer { app.prepareForTermination() }
    var calls = 0
    _ = PlayerConnectionModel(appModel: app, query: { _ in calls += 1; return (true, false, false) })
    XCTAssertEqual(calls, 0)
  }
  func testPermissionRefreshRunsOffMainThreadAndPublishesResults() async throws {
    let app = AppModel(microphoneMonitor: SilentMonitor())
    defer { app.prepareForTermination() }
    let model = PlayerConnectionModel(appModel: app, query: { _ in
      XCTAssertFalse(Thread.isMainThread)
      return (true, false, false)
    })
    model.refresh()
    for _ in 0..<100 where model.statuses.isEmpty {
      try await Task.sleep(nanoseconds: 10_000_000)
    }
    XCTAssertEqual(model.statuses["com.spotify.client"]?.authorized, true)
    XCTAssertEqual(model.statuses["com.apple.Music"]?.authorized, true)
  }
}
private final class SilentMonitor: MicrophoneMonitoring {
  var onChange: ((MicrophoneSnapshot) -> Void)?
  func start() {}
  func stop() {}
  func refresh() {}
}
