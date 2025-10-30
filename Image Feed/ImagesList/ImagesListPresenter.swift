import Foundation
import UIKit

// MARK: - View
protocol ImagesListViewProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set }
    func reloadRows(at indexPaths: [IndexPath])
    func insertRows(at indexPaths: [IndexPath])
    func setLikeButtonEnabled(_ enabled: Bool, at indexPath: IndexPath)
    func showLikeError()
}

// MARK: - Presenter
protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewProtocol? { get set }
    var numberOfRows: Int { get }
    func viewDidLoad()
    func willDisplayCell(at indexPath: IndexPath)
    func photo(at indexPath: IndexPath) -> Photo
    func toggleLike(at indexPath: IndexPath)
}

// MARK: - Dependency abstraction
protocol ImagesProviding: AnyObject {
    var photos: [Photo] { get }
    func fetchPhotosNextPage()
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void)
    static var didChangeNotification: Notification.Name { get }
}

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewProtocol?

    private let service: ImagesProviding
    private var observer: NSObjectProtocol?
    private var lastKnownCount = 0

    init(service: ImagesProviding) {
        self.service = service
    }

    deinit {
        if let o = observer { NotificationCenter.default.removeObserver(o) }
    }

    var numberOfRows: Int { service.photos.count }

    func viewDidLoad() {
        observer = NotificationCenter.default.addObserver(
            forName: type(of: service).didChangeNotification,
            object: service,
            queue: .main
        ) { [weak self] note in
            self?.handlePhotosUpdate(note)
        }

        lastKnownCount = service.photos.count
        if service.photos.isEmpty {
            service.fetchPhotosNextPage()
        }
    }

    func willDisplayCell(at indexPath: IndexPath) {
        if indexPath.row >= service.photos.count - 3 {
            service.fetchPhotosNextPage()
        }
    }

    func photo(at indexPath: IndexPath) -> Photo {
        service.photos[indexPath.row]
    }

    func toggleLike(at indexPath: IndexPath) {
        let p = service.photos[indexPath.row]
        view?.setLikeButtonEnabled(false, at: indexPath)
        service.changeLike(photoId: p.id, isLike: !p.isLiked) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.view?.setLikeButtonEnabled(true, at: indexPath)
                switch result {
                case .success:
                    self.view?.reloadRows(at: [indexPath])
                case .failure:
                    self.view?.showLikeError()
                }
            }
        }
    }

    // MARK: - Private
    private func handlePhotosUpdate(_ note: Notification) {
        let newCount = service.photos.count

        if newCount > lastKnownCount {
            let inserted = (lastKnownCount..<newCount).map { IndexPath(row: $0, section: 0) }
            lastKnownCount = newCount
            view?.insertRows(at: inserted)
            return
        }

        if let idx = note.userInfo?["changedIndex"] as? Int {
            lastKnownCount = newCount
            view?.reloadRows(at: [IndexPath(row: idx, section: 0)])
        } else {
            lastKnownCount = newCount
            let all = (0..<newCount).map { IndexPath(row: $0, section: 0) }
            view?.reloadRows(at: all)
        }
    }
}

