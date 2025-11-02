import UIKit

struct OAuthTokenResponseBody: Codable {
    let access_token: String?
}

enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private let oauth2Storage = OAuth2TokenStorage()

    private init() {}

    private func createURLRequest(_ code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: Constants.finalURLString) else {
            debugPrint("Error in creating URL string for authorization request: createURLRequest -> OAuth2Service")
            return nil
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        guard let url = urlComponents.url else {
            debugPrint("Error of url from urlComponents.url for authorization request")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }

    /// Получаем OAuth-токен и кладём его в `OAuth2TokenStorage`
    func fetchOAuthToken(code: String, handler: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        guard lastCode != code else {
            handler(.failure(AuthServiceError.invalidRequest))
            return
        }

        task?.cancel()
        self.lastCode = code

        guard let request = createURLRequest(code) else {
            handler(.failure(AuthServiceError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error> ) in
            guard let self else { return }
            switch result {
            case .success(let info):
                guard let token = info.access_token else {
                    self.lastCode = nil
                    handler(.failure(AuthServiceError.invalidRequest))
                    return
                }
                self.oauth2Storage.token = token
                handler(.success(token))

            case .failure(let error):
                debugPrint("Cannot receive token: fetchOAuthToken -> OAuth2Service")
                handler(.failure(error))
                self.lastCode = nil
            }
            self.lastCode = nil
            self.task = nil
        }

        self.task = task
        task.resume()
    }
}

