import Foundation

/// Errors that can occur when using the libHearts library.
///
/// These errors are thrown by ``EmojiArt`` during initialization or when
/// processing images.
public enum Error: Swift.Error {

  /// No emoji characters are available for use.
  ///
  /// This error occurs when:
  /// - The specified coherency threshold is too strict, filtering out all emoji
  /// - An unrecognized emoji group name was provided
  /// - An empty character set was provided
  case noCharacters

  /// A non-emoji character was provided in the character set.
  ///
  /// When creating an ``EmojiArt`` instance with a custom character set,
  /// all characters must be valid emoji. This error includes the offending
  /// character.
  ///
  /// - Parameter char: The character that is not a valid emoji.
  case nonEmojiCharacter(_ char: Character)

  /// The image could not be read or processed.
  ///
  /// This error occurs when:
  /// - The image data is corrupt
  /// - The image format is not supported by Core Image
  /// - The image could not be converted to a processable format
  case badImage
}

extension Error: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case .noCharacters:
        return String(localized: "No emoji characters in set", comment: "error")
      case .nonEmojiCharacter(let char):
        return String(localized: "Not an emoji character: \(String(char))", comment: "error")
      case .badImage:
        return String(localized: "Image could not be read", comment: "error")
    }
  }

  public var failureReason: String? {
    switch self {
      case .noCharacters:
        return String(
          localized: "You may have specified an invalid group name or non-emoji characters.",
          comment: "failure reason"
        )
      case .nonEmojiCharacter:
        return String(
          localized: "One of the characters you supplied is not an emoji.",
          comment: "failure reason"
        )
      case .badImage:
        return String(
          localized: "The image is corrupt or not in a supported format.",
          comment: "failure reason"
        )
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .noCharacters:
        return String(
          localized: "Confirm the group name is correct.",
          comment: "recovery suggestion"
        )
      case .nonEmojiCharacter:
        return String(
          localized: "Confirm that your list of characters includes only emoji.",
          comment: "recovery suggestion"
        )
      case .badImage:
        return String(
          localized: "Try converting the image to a supported format first.",
          comment: "recovery suggestion"
        )
    }
  }
}
