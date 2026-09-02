import ArgumentParser
import Foundation
import os

/// Cancels a task when a termination signal arrives, remembering which signal it was.
///
/// The signals are diverted as soon as the instance is created, so one that
/// arrives before the task is attached still cancels it rather than killing
/// the process.
struct SignalCancellation {
  private static let signalExitCodeBase: Int32 = 128

  private let state: OSAllocatedUnfairLock<State>
  private let sources: [any DispatchSourceSignal]

  /// The conventional exit code for the signal that was received, if any.
  var exitCode: ExitCode? {
    state.withLock { $0.signalNumber }.map { ExitCode(Self.signalExitCodeBase + $0) }
  }

  init(signals: [Int32]) {
    let state = OSAllocatedUnfairLock(initialState: State())
    self.state = state
    sources = signals.map { Self.makeSource(for: $0, recordingIn: state) }
  }

  private static func makeSource(
    for signalNumber: Int32,
    recordingIn state: OSAllocatedUnfairLock<State>
  ) -> any DispatchSourceSignal {
    signal(signalNumber, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .global())
    source.setEventHandler {
      let task = state.withLock { state in
        state.signalNumber = signalNumber
        return state.task
      }
      task?.cancel()
    }
    source.resume()
    return source
  }

  /// Cancels `task` when a signal arrives, or immediately if one already has.
  func attach(_ task: Task<Void, any Swift.Error>) {
    let alreadySignaled = state.withLock { state in
      state.task = task
      return state.signalNumber != nil
    }
    if alreadySignaled { task.cancel() }
  }

  /// Stops watching for signals.
  func invalidate() {
    sources.forEach { $0.cancel() }
  }

  private struct State {
    var task: Task<Void, any Swift.Error>?
    var signalNumber: Int32?
  }
}
