import XCTest
@testable import MicMinder

final class BoundedPermissionCheckTests: XCTestCase {
  func testHungCheckTimesOutWithoutStartingDuplicateWork() {
    let gate = DispatchSemaphore(value: 0)
    let started = expectation(description: "query started")
    let finished = expectation(description: "query finished")
    let check = BoundedPermissionCheck()
    defer { gate.signal(); wait(for: [finished], timeout: 1) }
    let start = Date()
    XCTAssertNil(check.run(key: "Music", timeout: 0.03) {
      started.fulfill()
      _ = gate.wait(timeout: .now() + 0.3)
      finished.fulfill()
      return 0
    })
    wait(for: [started], timeout: 1)
    XCTAssertLessThan(Date().timeIntervalSince(start), 0.5)
    XCTAssertNil(check.run(key: "Music", timeout: 0.03) {
      XCTFail("Must not accumulate workers while the original request is stuck")
      return 0
    })
    XCTAssertEqual(check.run(key: "Spotify", timeout: 1) { 7 }, 7)
  }

  func testSuccessfulChecksReadFreshResults() {
    let check = BoundedPermissionCheck()
    XCTAssertEqual(check.run(key: "Music", timeout: 1) { 0 }, 0)
    XCTAssertEqual(check.run(key: "Music", timeout: 1) { -1743 }, -1743)
  }

  func testLateSuccessDoesNotBecomeCachedAuthorization() {
    let check = BoundedPermissionCheck()
    let finished = expectation(description: "late completion")
    XCTAssertNil(check.run(key: "Music", timeout: 0.01) {
      Thread.sleep(forTimeInterval: 0.05)
      finished.fulfill()
      return 0
    })
    wait(for: [finished], timeout: 1)
    // Wait for the worker to release its in-flight slot, then require a fresh denial.
    var result: Int32?
    for _ in 0..<100 {
      result = check.run(key: "Music", timeout: 1) { -1743 }
      if result != nil { break }
      Thread.sleep(forTimeInterval: 0.001)
    }
    XCTAssertEqual(result, -1743)
  }
}
