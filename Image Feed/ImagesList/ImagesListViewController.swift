import UIKit

final class ImagesListViewController: UIViewController, ImagesListViewProtocol {

    @IBOutlet private var tableView: UITableView!

    // MVP
    var presenter: ImagesListPresenterProtocol?

    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        // ✅ для UI-тестов
        tableView.accessibilityIdentifier = "ImagesTable"

        presenter?.viewDidLoad()
    }

    // MARK: - ImagesListViewProtocol
    func reloadRows(at indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }
        tableView.reloadRows(at: indexPaths, with: .none)
    }

    func insertRows(at indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }

    func setLikeButtonEnabled(_ enabled: Bool, at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            cell.setLikeButtonEnabled(enabled)
        }
    }

    func showLikeError() {
        let alert = UIAlertController(title: "Ошибка",
                                      message: "Не удалось изменить лайк. Попробуйте позже.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let vc = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath,
                let presenter
            else { return }

            let model = presenter.photo(at: indexPath)
            vc.imageURL = URL(string: model.largeImageURL)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - UITableViewDataSource / Delegate (без изменений ниже)
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter?.numberOfRows ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }

        if let presenter {
            let photo = presenter.photo(at: indexPath)
            cell.configure(with: photo)
            cell.delegate = self
        }
        return cell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        presenter?.willDisplayCell(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let presenter else { return 0 }
        let photo = presenter.photo(at: indexPath)
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
        presenter?.toggleLike(at: indexPath)
    }
}

