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
                return t("No emoji characters in set", comment: "error")
            case let .nonEmojiCharacter(char):
                return t("Not an emoji character: %@", comment: "error",
                         String(char))
            case .badImage:
                return t("Image could not be read", comment: "error")
        }
    }
    
    public var failureReason: String? {
        switch self {
            case .noCharacters:
                return t("You may have specified an invalid group name or non-emoji characters.", comment: "failure reason")
            case .nonEmojiCharacter:
                return t("One of the characters you supplied is not an emoji.", comment: "failure reason")
            case .badImage:
                return t("The image is corrupt or not in a supported format.", comment: "failure reason")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
            case .noCharacters:
                return t("Confirm the group name is correct.", comment: "recovery suggestion")
            case .nonEmojiCharacter:
                return t("Confirm that your list of characters includes only emoji.", comment: "recovery suggestion")
            case .badImage:
                return t("Try converting the image to a supported format first.", comment: "recovery suggestion")
        }
    }
    
    private func t(_ key: String, comment: String, _ arguments: CVarArg...) -> String {
        let template = NSLocalizedString(key, bundle: Bundle.module, comment: comment)
        return String(format: template, arguments: arguments)
    }
}
