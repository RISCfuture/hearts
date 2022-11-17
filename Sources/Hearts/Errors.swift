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
                return t("No such file: %@", comment: "error",
                         path)
            case let .invalidURL(url):
                return t("Invalid URL: %@", comment: "error",
                         url)
            case .couldntLoadImage:
                return t("Couldn’t load image", comment: "error")
            case .badResponse:
                return t("Bad response from net request", comment: "error")
            case .couldntScaleImage:
                return t("Couldn’t resize image", comment: "error")
            case .invalidBackgroundColor:
                return t("Invalid background color", comment: "error")
        }
    }
    
    var failureReason: String? {
        switch self {
            case .invalidFilePath:
                return t("There is no file at that location.", comment: "failure reason")
            case .invalidURL:
                return t("That URL couldn’t be parsed.", comment: "failure reason")
            case .couldntLoadImage:
                return t("Core Image couldn’t parse the image file.", comment: "failure reason")
            case let .badResponse(response):
                if let response = response as? HTTPURLResponse {
                    return t("Non-successful HTTP response code %d.", comment: "failure reason",
                             response.statusCode)
                } else {
                    return t("Response was not recognized as an HTTP response.", comment: "failure reason")
                }
            case .couldntScaleImage:
                return t("The resize parameter may have been invalid.", comment: "failure reason")
            case .invalidBackgroundColor:
                return t("Background colors must be specified as comma-delimited RGB floats (e.g., “0.5,0.0,1.0”)", comment: "failure reason")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
            case .invalidFilePath:
                return t("Verify that the image file exists at that location.", comment: "recovery suggestion")
            case .invalidURL:
                return t("Make sure you are specifying the complete URL, including the scheme.", comment: "recovery suggestion")
            case .couldntLoadImage:
                return t("Verify that the file is a supported image type.", comment: "recovery suggestion")
            case .badResponse:
                return t("Check the URL to make sure it is working properly.", comment: "recovery suggestion")
            case .couldntScaleImage:
                return t("Try using a different resize parameter.", comment: "recovery suggestion")
            case .invalidBackgroundColor:
                return t("Check the formatting of your background color", comment: "recovery suggestion")
        }
    }
    
    private func t(_ key: String, comment: String, _ arguments: CVarArg...) -> String {
        let template = NSLocalizedString(key, bundle: Bundle.module, comment: comment)
        return String(format: template, arguments: arguments)
    }
}
