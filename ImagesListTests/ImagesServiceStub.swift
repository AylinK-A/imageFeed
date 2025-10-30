@testable import Image_Feed
import Foundation
import CoreGraphics

final class ImagesServiceStub: ImagesProviding {
    static let didChangeNotification = Notification.Name("ImagesServiceStub.didChange")

    private(set) var _photos: [Photo] = []
    var photos: [Photo] { _photos }

    private(set) var didFetchNextPage = false
    var likeResult: Result<Void, Error> = .success(())
    var likeCalledWith: (id: String, isLike: Bool)?

    func setPhotos(_ new: [Photo]) { _photos = new }

    func fetchPhotosNextPage() {
        didFetchNextPage = true
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        likeCalledWith = (photoId, isLike)
        completion(likeResult)
    }

    func postDidChange(changedIndex: Int? = nil) {
        var userInfo: [AnyHashable: Any] = ["photos": _photos]
        if let idx = changedIndex { userInfo["changedIndex"] = idx }
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self, userInfo: userInfo)
    }
}

func makePhoto(id: String, liked: Bool = false) -> Photo {
    Photo(
        id: id,
        size: CGSize(width: 1000, height: 500),
        createdAt: nil,
        welcomeDescription: nil,
        thumbImageURL: "https://example.com/\(id)_thumb.jpg",
        largeImageURL: "https://example.com/\(id)_full.jpg",
        isLiked: liked
    )
}

