import Foundation

public enum Error: Swift.Error {
    case noCharacters
    case nonEmojiCharacter(_ char: Character)
    case badImage
}

extension Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .noCharacters:
                return String(localized: "No emoji characters in set", comment: "error")
            case let .nonEmojiCharacter(char):
                return String(localized: "Not an emoji character: \(String(char))", comment: "error")
            case .badImage:
                return String(localized: "Image could not be read", comment: "error")
        }
    }

    public var failureReason: String? {
        switch self {
            case .noCharacters:
                return String(localized: "You may have specified an invalid group name or non-emoji characters.", comment: "failure reason")
            case .nonEmojiCharacter:
                return String(localized: "One of the characters you supplied is not an emoji.", comment: "failure reason")
            case .badImage:
                return String(localized: "The image is corrupt or not in a supported format.", comment: "failure reason")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
            case .noCharacters:
                return String(localized: "Confirm the group name is correct.", comment: "recovery suggestion")
            case .nonEmojiCharacter:
                return String(localized: "Confirm that your list of characters includes only emoji.", comment: "recovery suggestion")
            case .badImage:
                return String(localized: "Try converting the image to a supported format first.", comment: "recovery suggestion")
        }
    }
}
