import Foundation

package enum Error: Swift.Error {
    case invalidColor
}

extension Error: LocalizedError {
    package var errorDescription: String? {
        switch self {
            case .invalidColor:
                return t("Invalid color specified", comment: "error")
        }
    }
    
    package var failureReason: String? {
        switch self {
            case .invalidColor:
                return t("An invalid RGB color was specified.", comment: "error")
        }
    }
    
    package var recoverySuggestion: String? {
        switch self {
            case .invalidColor:
                return t("Verify the RGB color components are correct.", comment: "error")
        }
    }
    
    private func t(_ key: String, comment: String, _ arguments: CVarArg...) -> String {
        let template = NSLocalizedString(key, bundle: Bundle.module, comment: comment)
        return String(format: template, arguments: arguments)
    }
}
