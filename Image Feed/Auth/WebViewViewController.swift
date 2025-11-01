import UIKit
@preconcurrency import WebKit

final class WebViewViewController: UIViewController, WebViewViewControllerProtocol {

    // MARK: - MVP
    var presenter: WebViewPresenterProtocol?

    // MARK: - Delegates
    weak var delegate: WebViewViewControllerDelegate?
    weak var delegateSplashVC: SplashViewController?

    // MARK: - UI
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var progressView: UIProgressView!
    let backButton = UIButton()

    private var estimatedProgressObservation: NSKeyValueObservation?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        backButtonSetup()
        webView.accessibilityIdentifier = A11yID.Auth.webView

        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
            options: [],
            changeHandler: { [weak self] _, _ in
                guard let self = self else { return }
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
    func backButtonSetup() {
        let buttonImage = UIImage(named: "nav_back_button")
        backButton.setImage(buttonImage, for: .normal)
        backButton.addTarget(self, action: #selector(tapBackButton), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 9).isActive = true
        backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 9).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
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
        if let code = code(from: navigationAction) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url {
            return presenter?.code(from: url)
        }
        return nil
    }
}

