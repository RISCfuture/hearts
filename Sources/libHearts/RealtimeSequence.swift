import Foundation

/// A frame that knows when it should be shown.
///
/// Presentation times are measured from the start of the source. Conform your
/// own frame type to use ``_Concurrency/AsyncSequence/pacedToRealtime(clock:)``.
public protocol TimedFrame {
  /// The moment, relative to the start of the source, at which this frame is due.
  var presentationTime: Duration { get }
}

/// An asynchronous sequence that delivers timed frames on a wall clock.
///
/// The first frame is treated as due immediately. Each later frame is held back
/// until its presentation time arrives, and any frame whose time has already
/// passed (because the consumer was slow) is skipped. Playback therefore keeps
/// pace with real time at the cost of dropped frames.
///
/// Create one with ``_Concurrency/AsyncSequence/pacedToRealtime(clock:)``.
public struct RealtimeSequence<Base: AsyncSequence, C: Clock<Duration>>: AsyncSequence
where Base.Element: TimedFrame {

  /// The frame type produced by the base sequence.
  public typealias Element = Base.Element

  private let base: Base
  private let clock: C

  init(base: Base, clock: C) {
    self.base = base
    self.clock = clock
  }

  /// Creates an iterator that paces the base sequence against the clock.
  public func makeAsyncIterator() -> Iterator {
    .init(base: base.makeAsyncIterator(), clock: clock)
  }

  /// The iterator for a ``RealtimeSequence``.
  public struct Iterator: AsyncIteratorProtocol {
    private var base: Base.AsyncIterator
    private let clock: C
    private var start: C.Instant?

    init(base: Base.AsyncIterator, clock: C) {
      self.base = base
      self.clock = clock
    }

    /// Returns the next frame that is not yet stale, waiting until it is due.
    @concurrent
    public mutating func next() async throws -> Element? {
      while let frame = try await base.next() {
        let due = dueInstant(for: frame)
        guard due >= clock.now else { continue }
        if due > clock.now { try await clock.sleep(until: due, tolerance: nil) }
        return frame
      }
      return nil
    }

    private mutating func dueInstant(for frame: Element) -> C.Instant {
      let start = start ?? clock.now.advanced(by: .zero - frame.presentationTime)
      self.start = start
      return start.advanced(by: frame.presentationTime)
    }
  }
}

extension RealtimeSequence: Sendable where Base: Sendable {}

extension AsyncSequence where Element: TimedFrame {
  /// Paces this sequence so frames are delivered at their presentation times.
  ///
  /// - Parameter clock: The clock to pace against. Use `ContinuousClock()` for
  ///   real playback and a manual clock in tests.
  /// - Returns: A sequence that waits for early frames and skips stale ones.
  public func pacedToRealtime<C: Clock<Duration>>(clock: C) -> RealtimeSequence<Self, C> {
    .init(base: self, clock: clock)
  }
}
