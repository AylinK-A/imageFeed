import UIKit

private struct UserResult: Codable {
    let profileImage: userImage?
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

private struct userImage: Codable {
    let actualUserImage: String?
    
    enum CodingKeys: String, CodingKey {
        case actualUserImage = "medium"
    }
}

final class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    private let oauth2TokenStorage = OAuth2TokenStorage()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var userResult: UserResult?
    private(set) var avatarURL: String?
    
    func fetchProfileImageURL(username: String, _ handler: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        if task != nil {
            task?.cancel()
        }
        
        guard let token = oauth2TokenStorage.token else {
            handler(.failure(ProfileServiceError.invalidRequest))
            return
        }
        
        guard let request = createImageRequest(token, username) else {
            handler(.failure(ProfileServiceError.invalidRequest))
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult,Error>) in
            guard let self else { return }
            switch result {
            case .success(let info):
                avatarURL = info.profileImage?.actualUserImage
                guard let avatarURL = avatarURL else {return}
                handler(.success(avatarURL))
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL" : avatarURL]
                )
            case .failure(let error):
                debugPrint("Decoder error:", error.localizedDescription)
                handler(.failure(error))
            }
            self.task = nil
        }
        
        self.task = task
        task.resume()
    }

    
    private func createImageRequest(_ code: String, _ username: String) -> URLRequest? {
        let finalURLString = URL(string: Constants.baseAPIURLString + "/users/" + username)
        guard let url = finalURLString else {return nil}
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(code)", forHTTPHeaderField: "Authorization")
        return request
    }
    
}


