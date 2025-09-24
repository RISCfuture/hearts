import Foundation

package enum Error: Swift.Error {
  case invalidColor
}

extension Error: LocalizedError {
  package var errorDescription: String? {
    switch self {
      case .invalidColor:
        return String(localized: "Invalid color specified", comment: "error")
    }
  }

  package var failureReason: String? {
    switch self {
      case .invalidColor:
        return String(localized: "An invalid RGB color was specified.", comment: "error")
    }
  }

  package var recoverySuggestion: String? {
    switch self {
      case .invalidColor:
        return String(localized: "Verify the RGB color components are correct.", comment: "error")
    }
  }
}
