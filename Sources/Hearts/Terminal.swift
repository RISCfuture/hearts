import Darwin
import Foundation

/// Full-screen frame output on the controlling terminal.
///
/// Playback happens on the alternate screen with the cursor hidden, so the
/// shell's scrollback is untouched once playback ends.
struct Terminal: Sendable {
  private static let emojiColumns = 2
  private static let fallbackSize = Size(columns: 80, rows: 24)

  private static let escape = "\u{1B}["
  private static let enterSequence = escape + "?1049h" + escape + "2J" + escape + "?25l"
  private static let exitSequence = escape + "?25h" + escape + "?1049l"
  private static let homeSequence = escape + "H"
  private static let clearToEndOfLineSequence = escape + "K"

  private let size: Size

  init() {
    size = Self.querySize()
  }

  private static func querySize() -> Size {
    var window = winsize()
    guard isatty(STDOUT_FILENO) != 0, unsafe ioctl(STDOUT_FILENO, TIOCGWINSZ, &window) == 0,
      window.ws_col > 0, window.ws_row > 0
    else { return fallbackSize }
    return .init(columns: Int(window.ws_col), rows: Int(window.ws_row))
  }

  /// The widest frame, in emoji, that fits both dimensions of the terminal.
  func fittedWidth(aspectRatio: Double) -> UInt {
    let byColumns = (size.columns - 1) / Self.emojiColumns
    let byRows = Int(Double(size.rows) * aspectRatio)
    return UInt(max(1, min(byColumns, byRows)))
  }

  func enterPlayback() throws { try write(Self.enterSequence) }

  func exitPlayback() { try? write(Self.exitSequence) }

  /// Draws a frame from the top of the screen, erasing whatever each row previously held.
  func show(_ frame: String) throws {
    let rows = frame.split(separator: "\n", omittingEmptySubsequences: false)
    let cleared = rows.map { $0 + Self.clearToEndOfLineSequence }.joined(separator: "\n")
    try write(Self.homeSequence + cleared)
  }

  private func write(_ string: String) throws {
    try FileHandle.standardOutput.write(contentsOf: Data(string.utf8))
  }

  private struct Size {
    let columns: Int
    let rows: Int
  }
}
