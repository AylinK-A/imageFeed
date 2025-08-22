import Foundation

private struct OAuthTokenResponse: Decodable {
    let accessToken: String
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() { }

    private let storage = OAuth2TokenStorage()

    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: Constants.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]

        var comps = URLComponents()
        comps.queryItems = body.map { URLQueryItem(name: $0.key, value: $0.value) }
        let query = comps.percentEncodedQuery?.replacingOccurrences(of: "%20", with: "+")
        request.httpBody = query?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "OAuth2", code: -1))) }
                return
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let tokenResponse = try? decoder.decode(OAuthTokenResponse.self, from: data) {
                self?.storage.token = tokenResponse.accessToken
                DispatchQueue.main.async { completion(.success(tokenResponse.accessToken)) }
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "OAuth2", code: -2))) }
            }
        }.resume()
    }

    final class OAuth2TokenStorage {
        private let key = "oauth_access_token"
        var token: String? {
            get { UserDefaults.standard.string(forKey: key) }
            set {
                if let newValue = newValue {
                    UserDefaults.standard.set(newValue, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }
    }
}


