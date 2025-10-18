import Foundation
import CoreGraphics

// MARK: - DTO из сети

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

// MARK: - Модель для UI

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

// MARK: - Декодер дат Unsplash

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

// MARK: - Сервис

final class ImageListService {

    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    private(set) var photos: [Photo] = []

    private var lastLoadedPage: Int?
    private var isLoading = false
    private var task: URLSessionTask?

    private let perPage = 10
    private let authHeaderValue: String

    init(authHeaderValue: String) {
        self.authHeaderValue = authHeaderValue
    }

    deinit { task?.cancel() }

    func reset() {
        task?.cancel()
        task = nil
        isLoading = false
        lastLoadedPage = nil
        photos = []
    }

    /// Загружает следующую страницу. Если загрузка уже идёт — просто выходим.
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

        // Важно: ваш URLSession+data/objectTask уже вызывает completion на main.
        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            defer {
                self.isLoading = false
                self.task = nil
            }

            switch result {
            case .success(let results):
                let newPhotos = results.map { $0.toPhoto() }

                // защита от дублей
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
}

