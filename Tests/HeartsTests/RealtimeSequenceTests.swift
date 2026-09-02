import Foundation
import Testing

@testable import libHearts

@Suite
struct RealtimeSequenceTests {
  private static func frames(atMilliseconds times: [Int]) -> AsyncStream<StubFrame> {
    AsyncStream { continuation in
      for time in times { continuation.yield(.init(presentationTime: .milliseconds(time))) }
      continuation.finish()
    }
  }

  @Test
  func waitsForEachFramesPresentationTimeTreatingTheFirstFrameAsDueNow() async throws {
    let clock = TestClock()
    var received = [StubFrame]()
    let paced = Self.frames(atMilliseconds: [500, 600, 700]).pacedToRealtime(clock: clock)
    for try await frame in paced { received.append(frame) }

    #expect(
      received.map(\.presentationTime) == [
        .milliseconds(500), .milliseconds(600), .milliseconds(700)
      ]
    )
    #expect(clock.sleeps.map(\.offset) == [.milliseconds(100), .milliseconds(200)])
  }

  @Test
  func skipsFramesWhosePresentationTimeHasAlreadyPassed() async throws {
    let clock = TestClock()
    let paced = Self.frames(atMilliseconds: [0, 100, 200, 300]).pacedToRealtime(clock: clock)
    var iterator = paced.makeAsyncIterator()

    let first = try await iterator.next()
    clock.advance(by: .milliseconds(250))
    let second = try await iterator.next()
    let third = try await iterator.next()

    #expect(first?.presentationTime == .zero)
    #expect(second?.presentationTime == .milliseconds(300))
    #expect(third == nil)
    #expect(clock.sleeps.map(\.offset) == [.milliseconds(300)])
  }

  private struct StubFrame: TimedFrame, Equatable {
    let presentationTime: Duration
  }
}
