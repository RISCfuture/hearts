import ArgumentParser
import CoreImage
import Foundation
import UniformTypeIdentifiers
import libCommon
import libHearts

@main
struct Hearts: AsyncParsableCommand {
  private static let terminationSignals = [SIGINT, SIGTERM, SIGHUP]

  @Option(
    name: .shortAndLong,
    help: "Resize the image or video to the given width (in pixels)"
  )
  var width: UInt?

  @Option(
    name: .shortAndLong,
    help: "Amount of monochrome required for an emoji to be used (lower is stricter)"
  )
  var coherency: Float?

  @Option(
    name: .shortAndLong,
    help: "Only include emoji from this string or group name (overrides -c)"
  )
  var only: String?

  @Option(
    name: .shortAndLong,
    help:
      "The background color to use when calculating emoji color values, as 3 floats. This is the background color that the resulting emoji-art will look best against. (example: “0,0.5,1”)",
    transform: { str in
      let parts = str.split(separator: ",").map { Float($0) }
      guard parts.count == 3 else { throw Error.invalidBackgroundColor }
      let components = parts.compactMap(\.self)
      guard components.count == 3 else { throw Error.invalidBackgroundColor }
      guard components.allSatisfy({ (0.0...1.0).contains($0) }) else {
        throw Error.invalidBackgroundColor
      }
      return try Color(components)
    }
  )
  var background = Color.black

  @Flag(
    name: .shortAndLong,
    help:
      "Does not process or load the image; instead, returns the number of emoji that would be selected from, given the values of --coherency and --only."
  )
  var glyphCount = false

  @Argument(help: "The image file or URL, or local video file, to process")
  var file: String

  private static func isVideo(_ url: URL) -> Bool {
    UTType(filenameExtension: url.pathExtension)?.conforms(to: .movie) ?? false
  }

  mutating func run() async throws {
    let emojiArt: EmojiArt

    if let characters = parseOnlyCharacters() {
      emojiArt = try EmojiArt(characters: characters)
    } else if let groups = parseOnlyGroups() {
      emojiArt = try EmojiArt(groups: groups)
    } else if let coherency {
      emojiArt = try EmojiArt(coherency: coherency)
    } else {
      emojiArt = try EmojiArt()
    }
    await emojiArt.setBackgroundColor(background)

    if glyphCount {
      await print("\(emojiArt.characters.count)")
      return
    }

    let url = try toURL(path: file)
    if Self.isVideo(url) {
      try await play(url: url, using: emojiArt)
    } else {
      try await render(url: url, using: emojiArt)
    }
  }

  private func render(url: URL, using emojiArt: EmojiArt) async throws {
    var image = try await loadImage(url: url)
    if let width {
      image = try resize(image: image, width: Double(width))
    }
    print(try await emojiArt.process(image: image))
  }

  private func play(url: URL, using emojiArt: EmojiArt) async throws {
    guard url.isFileURL else { throw Error.remoteVideo(file) }
    let video = try await VideoInfo.load(url: url)
    let terminal = Terminal()
    let width = width ?? terminal.fittedWidth(aspectRatio: video.aspectRatio)

    let cancellation = SignalCancellation(signals: Self.terminationSignals)
    defer { cancellation.invalidate() }
    try terminal.enterPlayback()
    defer { terminal.exitPlayback() }

    let playback = Task {
      for try await frame in emojiArt.frames(of: video, width: width) {
        try terminal.show(frame.string)
      }
    }
    cancellation.attach(playback)

    do {
      try await playback.value
    } catch is CancellationError {}
    if let exitCode = cancellation.exitCode { throw exitCode }
  }

  private func toURL(path _: String) throws -> URL {
    let url: URL
    if file.contains("://") {
      guard let _url = URL(string: file) else {
        throw Error.invalidURL(file)
      }
      url = _url
    } else {
      guard FileManager.default.fileExists(atPath: file) else {
        throw Error.invalidFilePath(file)
      }
      url = URL(filePath: file)
    }

    return url
  }

  private func loadImage(url: URL) async throws -> CIImage {
    if url.isFileURL {
      guard let image = CIImage(contentsOf: url) else {
        throw Error.couldntLoadImage
      }
      return image
    }

    let session = URLSession(configuration: .ephemeral)
    let (data, response) = try await session.data(from: url)

    guard let response = response as? HTTPURLResponse else {
      throw Error.badResponse(response)
    }
    guard response.statusCode / 100 == 2 else {
      throw Error.badResponse(response)
    }

    guard let image = CIImage(data: data) else {
      throw Error.couldntLoadImage
    }
    return image
  }

  private func parseOnlyCharacters() -> Set<Character>? {
    guard let only else { return nil }
    let chars = Set(only)
    guard chars.allSatisfy(\.containsEmoji) else { return nil }
    return chars
  }

  private func parseOnlyGroups() -> [String]? {
    guard let only else { return nil }
    return only.components(separatedBy: ",")
  }

  private func resize(image: CIImage, width: Double) throws -> CIImage {
    let aspectRatio = image.extent.width / image.extent.height
    let scale = width / image.extent.width

    return image.applyingFilter(
      "CILanczosScaleTransform",
      parameters: [
        kCIInputAspectRatioKey: aspectRatio,
        kCIInputScaleKey: scale
      ]
    )
  }
}
