import Foundation
import libCommon

/// The emoji available for rendering, each paired with its average color.
///
/// Matching is a nearest-color search over the palette using a perceptually
/// weighted RGB distance. Entries are sorted by character so ties resolve the
/// same way every time.
struct Palette: Sendable {
  private let entries: [(character: Character, color: Color)]

  init(characters: Set<Character>) throws {
    guard !characters.isEmpty else { throw Error.noCharacters }
    entries = try characters.sorted().map { character in
      guard let data = ColorData.shared.for(character) else {
        throw Error.nonEmojiCharacter(character)
      }
      return (character, data.mean)
    }
  }

  private static func distance2(_ a: Color, _ b: Color) -> Float {
    // https://en.wikipedia.org/wiki/Color_difference

    let rMean = (a.red + b.red) / 2
    let delR = a.red - b.red
    let delG = a.green - b.green
    let delB = a.blue - b.blue

    let rFactor: Float
    let gFactor: Float
    let bFactor: Float
    if rMean < 0.5 {
      rFactor = 2
      gFactor = 4
      bFactor = 3
    } else {
      rFactor = 3
      gFactor = 4
      bFactor = 2
    }

    return rFactor * delR * delR + gFactor * delG * delG + bFactor * delB * delB
  }

  /// Renders rows of pixels as lines of emoji, blending transparency with `background`.
  ///
  /// Each color is matched once per call and reused across all of the rows,
  /// which matters for flat artwork and video frames.
  func render<Rows: Sequence>(_ rows: Rows, background: Color) throws -> String
  where Rows.Element: Sequence, Rows.Element.Element == ColorAlpha {
    var memo = [Color: Character]()
    func emoji(for pixel: ColorAlpha) throws -> Character {
      let color = try pixel.premultiply(background: background)
      if let hit = memo[color] { return hit }
      let found = closest(to: color)
      memo[color] = found
      return found
    }
    return try rows.map { try String($0.map(emoji)) }.joined(separator: "\n")
  }

  private func closest(to color: Color) -> Character {
    entries.lazy.map { ($0.character, Self.distance2($0.color, color)) }.min { $0.1 < $1.1 }!.0
  }
}
