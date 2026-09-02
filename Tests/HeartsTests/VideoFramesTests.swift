import Foundation
import Testing

@testable import libHearts

@Suite
struct VideoInfoTests {
  @Test
  func appliesTheTrackRotationToItsSize() async throws {
    let info = try await VideoInfo.load(url: Fixtures.rotatedVideo)
    #expect(info.size == CGSize(width: 16, height: 32))
  }
}

@Suite
struct VideoFramesTests {
  private static func solidFrame(of emoji: String) -> String {
    Array(repeating: String(repeating: emoji, count: 4), count: 4).joined(separator: "\n")
  }

  @Test
  func decodesEveryFrameScaledToTheRequestedSizeWithItsPresentationTime() async throws {
    let emojiArt = try EmojiArt(characters: Set("🟥🟩🟦"))
    let video = try await VideoInfo.load(url: Fixtures.basicVideo)
    var rendered = [String]()
    var times = [Duration]()

    for try await frame in VideoFrames(video: video, size: .init(width: 4, height: 4)) {
      times.append(frame.presentationTime)
      rendered.append(try await emojiArt.process(image: frame.image))
    }

    #expect(times == (0..<10).map { .milliseconds($0 * 100) })
    #expect(rendered == (0..<10).map { Self.solidFrame(of: ["🟥", "🟩", "🟦"][$0 % 3]) })
  }

  @Test
  func decodesRotatedVideoInItsDisplayOrientation() async throws {
    let emojiArt = try EmojiArt(characters: Set("🟥🟦"))
    let video = try await VideoInfo.load(url: Fixtures.rotatedVideo)
    var iterator = VideoFrames(video: video, size: .init(width: 2, height: 4)).makeAsyncIterator()

    let frame = try #require(try await iterator.next())

    #expect(try await emojiArt.process(image: frame.image) == "🟦🟦\n🟦🟦\n🟥🟥\n🟥🟥")
  }

  @Test
  func throwsForAFileWithNoVideoTrack() async {
    await #expect(throws: libHearts.Error.self) {
      _ = try await VideoInfo.load(url: Fixtures.image)
    }
  }
}

enum Fixtures {
  static let basicVideo = Bundle.module.url(forResource: "basic", withExtension: "mov")!
  static let rotatedVideo = Bundle.module.url(forResource: "rotated", withExtension: "mov")!
  static let image = Bundle.module.url(forResource: "basic", withExtension: "png")!
}
