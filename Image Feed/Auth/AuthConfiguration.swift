import Foundation

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURL: URL
    let authURLString: String
}

extension AuthConfiguration {
    static var standard: AuthConfiguration {
        guard let baseURL = URL(string: Constants.baseAPIURLString) else {
            preconditionFailure("Invalid baseAPIURLString in Constants")
        }

        return AuthConfiguration(
            accessKey: Constants.accessKey,
            secretKey: Constants.secretKey,
            redirectURI: Constants.redirectURI,
            accessScope: Constants.accessScope,
            defaultBaseURL: baseURL,
            authURLString: "https://unsplash.com/oauth/authorize"
        )
    }
}

