@preconcurrency import CoreImage
import Foundation
import libCommon

/// Generates emoji-art from images by matching pixels to emoji colors.
///
/// `EmojiArt` is an actor that transforms images into strings of emoji characters.
/// Each pixel in the source image is replaced with an emoji whose average color
/// best matches that pixel's color.
///
/// ## Creating an Instance
///
/// You can create an `EmojiArt` instance in several ways:
///
/// ```swift
/// // Default: uses emoji with uniform colors
/// let emojiArt = try await EmojiArt()
///
/// // Stricter coherency for cleaner output
/// let strict = try await EmojiArt(coherency: 0.1)
///
/// // Use emoji from a specific Unicode group
/// let flags = try await EmojiArt(group: "flags")
///
/// // Use a custom set of emoji
/// let hearts = try EmojiArt(characters: Set("❤️🧡💛💚💙💜"))
/// ```
///
/// ## Processing Images
///
/// Call ``process(image:)`` to convert an image to emoji-art:
///
/// ```swift
/// let result = try await emojiArt.process(image: myCIImage)
/// print(result)
/// ```
///
/// > Important: The image is not automatically scaled. Each pixel becomes one
/// > emoji character, so scale your image to the desired width first.
public actor EmojiArt {

  /// The default color coherency threshold.
  ///
  /// Color coherency measures how uniform an emoji's colors are. A value of `0.2`
  /// provides a good balance between variety and visual clarity. Lower values are
  /// stricter (fewer emoji with more uniform colors), while higher values include
  /// more varied emoji.
  ///
  /// - SeeAlso: ``init(coherency:)``
  public static let defaultCoherency: Float = 0.2

  /// The background color used when processing images with transparency.
  ///
  /// When an image pixel has partial transparency, the library blends it with
  /// this background color before finding a matching emoji. Set this to match
  /// the actual background where the emoji-art will be displayed.
  ///
  /// The default value is black.
  ///
  /// - SeeAlso: ``setBackgroundColor(_:)``
  public var backgroundColor = Color.black

  /// The set of emoji characters available for use in the generated emoji-art.
  ///
  /// This property contains all emoji that may appear in the output. The actual
  /// emoji used depend on the colors in your source image.
  public let characters: Set<Character>

  /// Creates an instance that uses emoji filtered by color coherency.
  ///
  /// Emoji with coherency below the threshold are excluded. This filters out
  /// emoji with varied colors (like faces) and keeps emoji with uniform colors
  /// (like shapes and symbols).
  ///
  /// - Parameter coherency: The maximum color standard deviation to allow.
  ///   Lower values are stricter. Defaults to ``defaultCoherency``.
  ///
  /// - Throws: ``Error/noCharacters`` if no emoji meet the coherency threshold.
  public init(coherency: Float = EmojiArt.defaultCoherency) async throws {
    try await self.init(characters: ColorData.shared.emojiWithCoherency(coherency))
  }

  /// Creates an instance that uses a specific set of emoji characters.
  ///
  /// Use this initializer when you want complete control over which emoji
  /// appear in the output.
  ///
  /// ```swift
  /// let hearts = try EmojiArt(characters: Set("❤️🧡💛💚💙💜🩷🤎🖤🤍"))
  /// ```
  ///
  /// - Parameter characters: The set of emoji characters to use.
  ///
  /// - Throws: ``Error/noCharacters`` if the set is empty.
  ///   ``Error/nonEmojiCharacter(_:)`` if any character is not a valid emoji.
  public init(characters: Set<Character>) throws {
    self.characters = characters
  }

  /// Creates an instance that uses emoji from a Unicode emoji group.
  ///
  /// Unicode organizes emoji into groups like "flags", "food-drink", and
  /// "animals-nature". This initializer loads all emoji from the specified group.
  ///
  /// ```swift
  /// let flags = try await EmojiArt(group: "flags")
  /// ```
  ///
  /// - Parameter group: The name of the emoji group, using lowercase with
  ///   hyphens (e.g., "food-drink", "animals-nature").
  ///
  /// - Throws: ``Error/noCharacters`` if the group name is not recognized.
  public init(group: String) async throws {
    try await self.init(characters: Groups.shared.characters(for: group))
  }

  /// Creates an instance that uses emoji from multiple Unicode emoji groups.
  ///
  /// Combines emoji from all specified groups into a single available set.
  ///
  /// ```swift
  /// let nature = try await EmojiArt(groups: ["animals-nature", "travel-places"])
  /// ```
  ///
  /// - Parameter groups: An array of emoji group names.
  ///
  /// - Throws: ``Error/noCharacters`` if no groups are recognized.
  public init(groups: [String]) async throws {
    try await self.init(characters: Groups.shared.characters(for: groups))
  }

  /// Sets the background color for transparency blending.
  ///
  /// Call this method before processing images that have transparency. The
  /// background color affects how transparent pixels are matched to emoji.
  ///
  /// - Parameter color: The background color to blend with transparent pixels.
  public func setBackgroundColor(_ color: Color) { backgroundColor = color }

  /// Processes an image and returns emoji-art.
  ///
  /// Each pixel in the image is replaced with an emoji whose average color
  /// best matches the pixel's color. The result is a string with newlines
  /// separating each row.
  ///
  /// ```swift
  /// let result = try await emojiArt.process(image: myCIImage)
  /// print(result)
  /// ```
  ///
  /// > Note: The image is processed at its native resolution. Each pixel
  /// > becomes one emoji character. Scale your image before processing to
  /// > control the output size.
  ///
  /// - Parameter image: The image to convert to emoji-art.
  ///
  /// - Returns: A string of emoji characters representing the image, with
  ///   newline characters separating each row.
  ///
  /// - Throws: ``Error/badImage`` if the image cannot be processed.
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
