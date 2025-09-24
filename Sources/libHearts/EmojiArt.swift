@preconcurrency import CoreImage
import Foundation
import libCommon

/// Generates "emoji-art" from strings.
public actor EmojiArt {

  /// Default color coherency: a measure of how similar the colors of the
  /// individual pixels of an emoji must be for it to be used to represent a
  /// colored pixel in the source image. Lower is stricter.
  public static let defaultCoherency: Float = 0.2

  /// The background color that the resulting emoji-art will be displayed
  /// against (affects transparency).
  public var backgroundColor = Color.black

  /// The set of emoji characters to use.
  public let characters: Set<Character>

  /// Creates an instance that uses emoji matching a certain color coherency.
  ///
  /// - Parameter coherency: See ``defaultCoherency``.
  public init(coherency: Float = EmojiArt.defaultCoherency) async throws {
    try await self.init(characters: ColorData.shared.emojiWithCoherency(coherency))
  }

  /// Creates an instance that uses emoji from a given set.
  ///
  /// - Parameter characters: The set of emoji characters to use.
  public init(characters: Set<Character>) throws {
    self.characters = characters
  }

  /// Creates an instance that uses emoji from a defined Unicode emoji group.
  ///
  /// - Parameter group: The name of the emoji group.
  public init(group: String) async throws {
    try await self.init(characters: Groups.shared.characters(for: group))
  }

  /// Creates an instance that uses emoji from multiple Unicode emoji groups.
  ///
  /// - Parameter groups: The names of the emoji groups.
  public init(groups: [String]) async throws {
    try await self.init(characters: Groups.shared.characters(for: groups))
  }

  /// Sets the assumed background color of the output string.
  public func setBackgroundColor(_ color: Color) { backgroundColor = color }

  /// Analyzes an image and returns emoji-art. Each pixel in the image will be
  /// represented as an emoji character. (The image will not be scaled.)
  ///
  /// - Parameter image: The image to process.
  /// - Returns: The emoji-art string, with newlines.
  public func process(image: CIImage) async throws -> String {
    let chars = try await withThrowingTaskGroup(
      of: (Int, Character).self,
      returning: Array<Character>.self
    ) { group in
      guard let cgImage = cgImage(from: image),
        let pixels = cgImagePixels(cgImage)
      else { throw Error.badImage }

      var array = Array(
        repeating: Character("."),
        count: Int(image.extent.width * image.extent.height)
      )

      for (n, pixel) in pixels.enumerated() {
        group.addTask {
          let char =
            await self.closestEmoji(for: try pixel.premultiply(background: self.backgroundColor))
            ?? " "
          return (n, char)
        }
      }

      for try await pair in group { array[pair.0] = pair.1 }
      return array
    }

    return
      chars
      .inGroupsOf(Int(image.extent.width))
      .map { String($0) }
      .joined(separator: "\n")
  }

  private func closestEmoji(for color: Color) async -> Character? {
    var min: Character?
    var minDist: Float?
    for character in characters {
      let charColor = await ColorData.shared.for(character)!
      let dist = distance2(charColor.mean, color)

      guard min != nil, minDist != nil else {
        min = character
        minDist = dist
        continue
      }
      if dist < minDist! {
        min = character
        minDist = dist
      }
    }

    return min
  }

  private func distance2(_ a: Color, _ b: Color) -> Float {
    // https://en.wikipedia.org/wiki/Color_difference

    let rMean = (a.red + b.red) / 2
    let delR2 = pow(a.red - b.red, 2)
    let delG2 = pow(a.green - b.green, 2)
    let delB2 = pow(a.blue - b.blue, 2)

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

    return rFactor * delR2 + gFactor * delG2 + bFactor * delB2
  }
}
