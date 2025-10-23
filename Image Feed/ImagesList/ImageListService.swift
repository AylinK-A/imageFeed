import Foundation
import CoreGraphics

struct UrlsResult: Decodable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct PhotoResult: Decodable {
    let id: String
    let createdAt: Date?
    let width: Int
    let height: Int
    let description: String?
    let likedByUser: Bool
    let urls: UrlsResult

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case width
        case height
        case description
        case likedByUser = "liked_by_user"
        case urls
    }
}

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}

extension PhotoResult {
    func toPhoto() -> Photo {
        Photo(
            id: id,
            size: CGSize(width: width, height: height),
            createdAt: createdAt,
            welcomeDescription: description,
            thumbImageURL: urls.thumb,
            largeImageURL: urls.full,
            isLiked: likedByUser
        )
    }
}

private extension JSONDecoder {
    static let unsplash: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            let withMs = ISO8601DateFormatter()
            withMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let noMs = ISO8601DateFormatter()
            noMs.formatOptions = [.withInternetDateTime]
            if let date = withMs.date(from: s) ?? noMs.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Bad ISO8601: \(s)")
        }
        return d
    }()
}

final class ImageListService {

    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")

    private(set) var photos: [Photo] = []

    private var lastLoadedPage: Int?
    private var isLoading = false
    private var task: URLSessionTask?
    private var likeTask: URLSessionTask?

    private let perPage = 10
    private var authHeaderValue: String {
            if let token = OAuth2TokenStorage().token, !token.isEmpty {
                return "Bearer \(token)"
            } else {
                return "Client-ID \(Constants.accessKey)"
            }
        }

    init() {}

    deinit { task?.cancel() }

    func reset() {
        task?.cancel()
        task = nil
        isLoading = false
        lastLoadedPage = nil
        photos = []
    }

    func fetchPhotosNextPage() {
        guard !isLoading else { return }

        let nextPage = (lastLoadedPage ?? 0) + 1
        isLoading = true

        var components = URLComponents(string: "https://api.unsplash.com/photos")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(nextPage)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")

        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            defer {
                self.isLoading = false
                self.task = nil
            }

            switch result {
            case .success(let results):
                let newPhotos = results.map { $0.toPhoto() }

                let existingIDs = Set(self.photos.map(\.id))
                let unique = newPhotos.filter { !existingIDs.contains($0.id) }

                self.photos.append(contentsOf: unique)
                self.lastLoadedPage = nextPage

                NotificationCenter.default.post(
                    name: Self.didChangeNotification,
                    object: self,
                    userInfo: ["photos": self.photos]
                )

            case .failure(let error):
                debugPrint("ImageListService fetch error:", error.localizedDescription)
            }
        }

        task?.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)

        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            completion(.failure(NetworkError.urlSessionError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.data(for: request) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                DispatchQueue.main.async {
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let photo = self.photos[index]
                        let newPhoto = Photo(
                            id: photo.id,
                            size: photo.size,
                            createdAt: photo.createdAt,
                            welcomeDescription: photo.welcomeDescription,
                            thumbImageURL: photo.thumbImageURL,
                            largeImageURL: photo.largeImageURL,
                            isLiked: !photo.isLiked
                        )
                        self.photos = self.photos.withReplaced(itemAt: index, newValue: newPhoto)

                        NotificationCenter.default.post(
                            name: Self.didChangeNotification,
                            object: self,
                            userInfo: ["photos": self.photos,
                                       "changedIndex": index]
                        )
                    }
                    completion(.success(()))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> [Element] {
        var copy = self
        copy[index] = newValue
        return copy
    }
}
