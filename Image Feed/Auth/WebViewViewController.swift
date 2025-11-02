import UIKit
import WebKit

final class WebViewViewController: UIViewController, WebViewViewControllerProtocol {

    // MARK: - MVP
    var presenter: WebViewPresenterProtocol?

    // MARK: - Delegates
    weak var delegate: WebViewViewControllerDelegate?

    // MARK: - UI
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var progressView: UIProgressView!
    private let backButton = UIButton()

    private var estimatedProgressObservation: NSKeyValueObservation?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackButton()

        webView.accessibilityIdentifier = A11yID.Auth.webView
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
            options: [],
            changeHandler: { [weak self] _, _ in
                guard let self else { return }
                self.presenter?.didUpdateProgressValue(self.webView.estimatedProgress)
            })

        webView.navigationDelegate = self
        presenter?.viewDidLoad()
    }

    // MARK: - WebViewViewControllerProtocol
    func load(_ request: URLRequest) {
        webView.load(request)
    }

    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }

    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }

    // MARK: - UI
    private func setupBackButton() {
        let image = UIImage(named: "nav_back_button")
        backButton.setImage(image, for: .normal)
        backButton.addTarget(self, action: #selector(tapBackButton), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 9),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 9),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.widthAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func tapBackButton() {
        delegate?.webViewViewControllerDidCancel(self)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url,
           let code = presenter?.code(from: url) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

