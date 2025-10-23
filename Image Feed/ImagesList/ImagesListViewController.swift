import UIKit

final class ImagesListViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!

    private lazy var imagesService = ImageListService()
    private var photos: [Photo] = []

    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePhotosUpdate(_:)),
            name: ImageListService.didChangeNotification,
            object: imagesService
        )

        if photos.isEmpty {
            imagesService.fetchPhotosNextPage()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handlePhotosUpdate(_ note: Notification) {
        assert(Thread.isMainThread)

        let oldCountInTable = tableView.numberOfRows(inSection: 0)
        let newPhotos = imagesService.photos
        let newCount = newPhotos.count
        
        photos = newPhotos

        if newCount > oldCountInTable {
                // добавились новые строки — вставим хвост
                let inserted = (oldCountInTable..<newCount).map { IndexPath(row: $0, section: 0) }
                tableView.performBatchUpdates {
                    tableView.insertRows(at: inserted, with: .automatic)
                }
                return
            }
        if let idx = note.userInfo?["changedIndex"] as? Int {
                let ip = IndexPath(row: idx, section: 0)
                // обновляем конкретную ячейку (configure поставит правильную иконку)
                tableView.reloadRows(at: [ip], with: .none)
            } else {
                // на всякий случай: если уведомление без индекса
                if let visible = tableView.indexPathsForVisibleRows, !visible.isEmpty {
                    tableView.reloadRows(at: visible, with: .none)
                } else {
                    tableView.reloadData()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let vc = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else { return }

            let model = photos[indexPath.row]
            vc.imageURL = URL(string: model.largeImageURL)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }
        cell.configure(with: photos[indexPath.row])
        cell.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesService.fetchPhotosNextPage()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let tableWidth = tableView.bounds.width
        let imageWidth = max(photo.size.width, 1)
        let scale = tableWidth / imageWidth
        let imageHeight = photo.size.height * scale
        return imageHeight
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imagesListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]

        cell.setLikeButtonEnabled(false)

        imagesService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self else { return }
            if let currentCell = self.tableView.cellForRow(at: indexPath) as? ImagesListCell {
                currentCell.setLikeButtonEnabled(true)
            }

            switch result {
            case .success:
                break
            case .failure:
                let alert = UIAlertController(title: "Ошибка",
                                              message: "Не удалось изменить лайк. Попробуйте позже.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}


