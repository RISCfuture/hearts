import Foundation
import os

/// A clock that never waits: sleeping jumps `now` forward to the deadline and
/// records it, so pacing logic can be verified deterministically.
struct TestClock: Clock {
  typealias Duration = Swift.Duration

  private let state = OSAllocatedUnfairLock(initialState: State())

  var now: Instant { state.withLock { $0.now } }
  var minimumResolution: Duration { .zero }
  var sleeps: [Instant] { state.withLock { $0.sleeps } }

  // swiftlint:disable:next async_without_await
  func sleep(until deadline: Instant, tolerance _: Duration?) async throws {
    try Task.checkCancellation()
    state.withLock { state in
      state.sleeps.append(deadline)
      state.now = max(state.now, deadline)
    }
  }

  func advance(by duration: Duration) {
    state.withLock { $0.now = $0.now.advanced(by: duration) }
  }

  struct Instant: InstantProtocol {
    let offset: Duration

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.offset < rhs.offset }

    func advanced(by duration: Duration) -> Self { .init(offset: offset + duration) }
    func duration(to other: Self) -> Duration { other.offset - offset }
  }

  private struct State {
    var now = Instant(offset: .zero)
    var sleeps = [Instant]()
  }
}
