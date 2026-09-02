import CoreImage
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
/// let emojiArt = try EmojiArt()
///
/// // Stricter coherency for cleaner output
/// let strict = try EmojiArt(coherency: 0.1)
///
/// // Use emoji from a specific Unicode group
/// let flags = try EmojiArt(group: "flags")
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

  /// The sequence returned by ``frames(of:width:clock:)``.
  public typealias Frames<C: Clock<Duration>> =
    RealtimeSequence<AsyncThrowingMapSequence<VideoFrames, EmojiFrame>, C>

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

  private let palette: Palette

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
  public init(coherency: Float = EmojiArt.defaultCoherency) throws {
    try self.init(characters: ColorData.shared.emojiWithCoherency(coherency))
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
    palette = try Palette(characters: characters)
  }

  /// Creates an instance that uses emoji from a Unicode emoji group.
  ///
  /// Unicode organizes emoji into groups like "flags", "food-drink", and
  /// "animals-nature". This initializer loads all emoji from the specified group.
  ///
  /// ```swift
  /// let flags = try EmojiArt(group: "flags")
  /// ```
  ///
  /// - Parameter group: The name of the emoji group, using lowercase with
  ///   hyphens (e.g., "food-drink", "animals-nature").
  ///
  /// - Throws: ``Error/noCharacters`` if the group name is not recognized.
  public init(group: String) throws {
    try self.init(characters: Groups.shared.characters(for: group))
  }

  /// Creates an instance that uses emoji from multiple Unicode emoji groups.
  ///
  /// Combines emoji from all specified groups into a single available set.
  ///
  /// ```swift
  /// let nature = try EmojiArt(groups: ["animals-nature", "travel-places"])
  /// ```
  ///
  /// - Parameter groups: An array of emoji group names.
  ///
  /// - Throws: ``Error/noCharacters`` if no groups are recognized.
  public init(groups: [String]) throws {
    try self.init(characters: Groups.shared.characters(for: groups))
  }

  private static func rowsPerBand(rowCount: Int) -> Int {
    let bandCount = ProcessInfo.processInfo.activeProcessorCount
    return max(1, Int((Double(rowCount) / Double(bandCount)).rounded(.up)))
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
    guard let cgImage = cgImage(from: image), cgImage.width > 0, let pixels = cgImagePixels(cgImage)
    else { throw Error.badImage }

    let rows = Array(pixels).chunks(of: cgImage.width)
    let bands = rows.chunks(of: Self.rowsPerBand(rowCount: rows.count))
    let background = backgroundColor
    let palette = palette

    let renderedBands = try await withThrowingTaskGroup(
      of: (Int, String).self,
      returning: [String].self
    ) { group in
      for (index, band) in bands.enumerated() {
        group.addTask { (index, try palette.render(band, background: background)) }
      }

      var array = Array(repeating: "", count: bands.count)
      for try await (index, band) in group { array[index] = band }
      return array
    }

    return renderedBands.joined(separator: "\n")
  }

  /// Plays a video as a sequence of emoji-art frames in real time.
  ///
  /// Each frame is decoded at `width` pixels wide (height follows the video's
  /// aspect ratio), converted with ``process(image:)``, and then delivered at
  /// its presentation time. A frame whose time has already passed by the time
  /// it is rendered is skipped, so playback finishes when the video would,
  /// regardless of rendering speed.
  ///
  /// ```swift
  /// let video = try await VideoInfo.load(url: url)
  /// for try await frame in emojiArt.frames(of: video, width: 80) {
  ///   print(frame.string)
  /// }
  /// ```
  ///
  /// Frames are decoded only as they are requested, so cancelling the consuming
  /// task, or ending iteration early, stops decoding.
  ///
  /// - Parameters:
  ///   - video: A local video file.
  ///   - width: The output width in emoji.
  ///   - clock: The clock that paces playback. Defaults to the continuous clock.
  ///
  /// - Returns: A sequence of rendered frames, one per displayed frame.
  ///
  /// - Throws: ``Error/badVideo`` if the video cannot be read.
  nonisolated public func frames<C: Clock<Duration>>(
    of video: VideoInfo,
    width: UInt,
    clock: C = ContinuousClock()
  ) -> Frames<C> {
    VideoFrames(video: video, size: video.frameSize(width: width))
      .map {
        EmojiFrame(
          presentationTime: $0.presentationTime,
          string: try await self.process(image: $0.image)
        )
      }
      .pacedToRealtime(clock: clock)
  }
}

/// One frame of a video rendered as emoji-art.
public struct EmojiFrame: TimedFrame, Sendable {

  /// When this frame is due, measured from the start of the video.
  public let presentationTime: Duration

  /// The rendered frame, with newline characters separating each row.
  public let string: String
}

extension RandomAccessCollection where Index == Int {
  fileprivate func chunks(of size: Int) -> [SubSequence] {
    stride(from: startIndex, to: endIndex, by: size).map { self[$0...].prefix(size) }
  }
}
