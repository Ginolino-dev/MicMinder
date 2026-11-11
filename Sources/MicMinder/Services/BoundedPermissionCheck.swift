import Foundation

// An Apple permission query has no cancellation API. Keep at most one worker
// per key, bound callers' waits, and never retain completed authorization.
final class BoundedPermissionCheck {
  private final class Request {
    let group = DispatchGroup()
    let deadline: DispatchTime
    var result: Int32?
    init(timeout: TimeInterval) {
      deadline = .now() + timeout
      group.enter()
    }
  }
  private let lock = NSLock()
  private var pending: [String: Request] = [:]

  func run(key: String, timeout: TimeInterval, operation: @escaping () -> Int32) -> Int32? {
    lock.lock()
    let request: Request
    if let existing = pending[key] {
      request = existing
    } else {
      request = Request(timeout: timeout)
      pending[key] = request
      DispatchQueue.global(qos: .userInitiated).async { [self] in
        let result = operation()
        lock.lock()
        request.result = result
        pending.removeValue(forKey: key)
        lock.unlock()
        request.group.leave()
      }
    }
    lock.unlock()
    guard DispatchTime.now() < request.deadline,
          request.group.wait(timeout: min(request.deadline, .now() + timeout)) == .success else { return nil }
    lock.lock()
    defer { lock.unlock() }
    return request.result
  }
}
