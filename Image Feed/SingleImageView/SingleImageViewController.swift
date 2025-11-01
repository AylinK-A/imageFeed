import UIKit

@MainActor
final class SingleImageViewController: UIViewController {

    var imageURL: URL?
    var image: UIImage?

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!

    private enum InitialMode { case fill, fit }
    private let initialMode: InitialMode = .fill

    private var hasAppeared = false
    private var didApplyInitialZoom = false

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.accessibilityIdentifier = A11yID.Feed.fullImage

        imageView.image = nil

        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 3.0
        scrollView.contentInsetAdjustmentBehavior = .never

        if let img = image {
            setImage(img)
        } else if let url = imageURL {
            loadImage(from: url)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didApplyInitialZoom = false
        scrollView.setZoomScale(1.0, animated: false)
        scrollView.contentInset = .zero
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
        applyInitialScaleAndCenterIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hasAppeared = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.didApplyInitialZoom = false
            self.applyInitialScaleAndCenterIfNeeded()
        }
    }

    @IBAction private func didTapBackButton(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction private func didTapShareButton(_ sender: Any) {
        guard let img = imageView.image else { return }
        present(UIActivityViewController(activityItems: [img], applicationActivities: nil), animated: true)
    }

    private func loadImage(from url: URL) {
        UIBlockingProgressHUD.show()
        ImageLoader.shared.loadImage(from: url.absoluteString) { [weak self] img in
            guard let self else { return }
            UIBlockingProgressHUD.dismiss()
            guard let img else {
                self.showError { [weak self] in self?.loadImage(from: url) }
                return
            }
            self.setImage(img)
        }
    }

    private func setImage(_ img: UIImage) {
        image = img

        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.image = img
        imageView.frame = CGRect(origin: .zero, size: img.size)

        scrollView.contentSize = img.size
        scrollView.contentInset = .zero

        didApplyInitialZoom = false
        if hasAppeared {
            DispatchQueue.main.async { [weak self] in
                self?.applyInitialScaleAndCenterIfNeeded()
            }
        }
    }

    private func applyInitialScaleAndCenterIfNeeded() {
        guard !didApplyInitialZoom, let img = imageView.image else { return }

        view.layoutIfNeeded()
        scrollView.layoutIfNeeded()

        let bounds = scrollView.bounds.size
        let imgSize = img.size
        guard bounds.width > 0, bounds.height > 0, imgSize.width > 0, imgSize.height > 0 else { return }

        let h = bounds.width  / imgSize.width
        let v = bounds.height / imgSize.height
        let target = (initialMode == .fill) ? max(h, v) : min(h, v)

        if target < scrollView.minimumZoomScale { scrollView.minimumZoomScale = target / 2 }
        if target > scrollView.maximumZoomScale { scrollView.maximumZoomScale = max(target, scrollView.maximumZoomScale * 2) }

        scrollView.setZoomScale(target, animated: false)
        centerViaInsets()

        didApplyInitialZoom = true
    }

    private func centerViaInsets() {
        let bounds = scrollView.bounds.size
        let size = imageView.frame.size
        let h = max(0, (bounds.width  - size.width)  / 2)
        let v = max(0, (bounds.height - size.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: v, left: h, bottom: v, right: h)
    }

    private func showError(retry: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Что-то пошло не так. Попробовать ещё раз?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default, handler: { _ in retry() }))
        present(alert, animated: true)
    }
}

@MainActor
extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerViaInsets() }
}

