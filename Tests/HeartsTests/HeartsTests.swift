import CoreImage
import Foundation
import Testing
import libCommon

@testable import libHearts

@Suite
struct `Emoji art processing` {
  private static func image(at url: URL) throws -> CIImage {
    try #require(CIImage(contentsOf: url))
  }

  private static func expected(_ name: String) throws -> String {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "txt"))
    return try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .newlines)
  }

  @Test
  func `converts an image into emoji-art`() async throws {
    let emojiArt = try EmojiArt()
    let string = try await emojiArt.process(image: Self.image(at: Fixtures.image))
    #expect(string == (try Self.expected("basic")))
  }

  @Test
  func `permits a custom coherency`() async throws {
    let emojiArt = try EmojiArt(coherency: 0.1)
    let string = try await emojiArt.process(image: Self.image(at: Fixtures.image))
    #expect(string == (try Self.expected("coherency")))
  }

  @Test
  func `permits a custom character set`() async throws {
    let emojiArt = try EmojiArt(characters: Set("📕📗📘📙📔📓"))
    let string = try await emojiArt.process(image: Self.image(at: Fixtures.image))
    #expect(string == (try Self.expected("chars")))
  }

  @Test
  func `permits a custom group`() async throws {
    let emojiArt = try EmojiArt(group: "hearts")
    let string = try await emojiArt.process(image: Self.image(at: Fixtures.image))
    #expect(string == (try Self.expected("group")))
  }

  @Test
  func `permits a custom background color`() async throws {
    let emojiArt = try EmojiArt()
    let transparent = try Self.image(at: Fixtures.transparentImage)

    let black = try await emojiArt.process(image: transparent)
    #expect(black == (try Self.expected("transparent-black")))

    await emojiArt.setBackgroundColor(try .init(red: 1, green: 1, blue: 1))
    let white = try await emojiArt.process(image: transparent)
    #expect(white == (try Self.expected("transparent-white")))
  }
}
