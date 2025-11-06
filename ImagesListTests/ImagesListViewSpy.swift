@testable import Image_Feed
import Foundation

final class ImagesListViewSpy: ImagesListViewProtocol {
    var presenter: ImagesListPresenterProtocol?

    private(set) var reloaded: [IndexPath] = []
    private(set) var inserted: [IndexPath] = []
    private(set) var likeEnabled: [(Bool, IndexPath)] = []
    private(set) var showLikeErrorCalled = false

    func reloadRows(at indexPaths: [IndexPath]) { reloaded.append(contentsOf: indexPaths) }
    func insertRows(at indexPaths: [IndexPath]) { inserted.append(contentsOf: indexPaths) }
    func setLikeButtonEnabled(_ enabled: Bool, at indexPath: IndexPath) {
        likeEnabled.append((enabled, indexPath))
    }
    func showLikeError() { showLikeErrorCalled = true }
}

