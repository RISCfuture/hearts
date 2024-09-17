import Foundation

enum Error: Swift.Error {
    case invalidFilePath(_ path: String)
    case invalidURL(_ url: String)
    case couldntLoadImage
    case badResponse(_ response: URLResponse)
    case couldntScaleImage
    case invalidBackgroundColor
}

extension Error: LocalizedError {
    var errorDescription: String? {
        switch self {
            case let .invalidFilePath(path):
                return String(localized: "No such file: \(path)", comment: "error")
            case let .invalidURL(url):
                return String(localized: "Invalid URL: \(url)", comment: "error")
            case .couldntLoadImage:
                return String(localized: "Couldn’t load image", comment: "error")
            case .badResponse:
                return String(localized: "Bad response from net request", comment: "error")
            case .couldntScaleImage:
                return String(localized: "Couldn’t resize image", comment: "error")
            case .invalidBackgroundColor:
                return String(localized: "Invalid background color", comment: "error")
        }
    }
    
    var failureReason: String? {
        switch self {
            case .invalidFilePath:
                return String(localized: "There is no file at that location.", comment: "failure reason")
            case .invalidURL:
                return String(localized: "That URL couldn’t be parsed.", comment: "failure reason")
            case .couldntLoadImage:
                return String(localized: "Core Image couldn’t parse the image file.", comment: "failure reason")
            case let .badResponse(response):
                if let response = response as? HTTPURLResponse {
                    return String(localized: "Non-successful HTTP response code \(response.statusCode).", comment: "failure reason")
                } else {
                    return String(localized: "Response was not recognized as an HTTP response.", comment: "failure reason")
                }
            case .couldntScaleImage:
                return String(localized: "The resize parameter may have been invalid.", comment: "failure reason")
            case .invalidBackgroundColor:
                return String(localized: "Background colors must be specified as comma-delimited RGB floats (e.g., “0.5,0.0,1.0”)", comment: "failure reason")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
            case .invalidFilePath:
                return String(localized: "Verify that the image file exists at that location.", comment: "recovery suggestion")
            case .invalidURL:
                return String(localized: "Make sure you are specifying the complete URL, including the scheme.", comment: "recovery suggestion")
            case .couldntLoadImage:
                return String(localized: "Verify that the file is a supported image type.", comment: "recovery suggestion")
            case .badResponse:
                return String(localized: "Check the URL to make sure it is working properly.", comment: "recovery suggestion")
            case .couldntScaleImage:
                return String(localized: "Try using a different resize parameter.", comment: "recovery suggestion")
            case .invalidBackgroundColor:
                return String(localized: "Check the formatting of your background color", comment: "recovery suggestion")
        }
    }
}
