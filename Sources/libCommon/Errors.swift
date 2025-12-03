import Foundation

/// Errors that can occur in libCommon operations.
package enum Error: Swift.Error {
  /// An invalid RGB color was specified.
  ///
  /// This error is thrown when creating a `Color` with components outside
  /// the valid range of 0.0 to 1.0.
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
