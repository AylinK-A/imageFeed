import UIKit

private struct ProfileResult: Decodable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName  = "last_name"
        case bio
    }
}

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String
}

enum ProfileServiceError: Error {
    case invalidRequest
}

final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private(set) var profile: Profile?

    // MARK: - Request builder

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version") // важно для Unsplash
        return request
    }

    // MARK: - Public

    func fetchProfile(_ token: String, handler: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)

        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            handler(.failure(ProfileServiceError.invalidRequest))
            return
        }

        task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self else { return }

            switch result {
            case .success(let dto):
                let fullName = [dto.firstName, dto.lastName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespaces)

                let profile = Profile(
                    username: dto.username,
                    name: fullName.isEmpty ? dto.username : fullName,
                    loginName: "@\(dto.username)",
                    bio: dto.bio ?? ""
                )
                self.profile = profile
                handler(.success(profile))

            case .failure(let error):
                handler(.failure(error))
            }

            self.task = nil
        }

        task?.resume()
    }
}

