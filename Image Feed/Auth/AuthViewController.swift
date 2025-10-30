import UIKit
import ProgressHUD

final class AuthViewController: UIViewController {
    private let ShowWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage()

    weak var delegate: AuthViewControllerDelegate?
    @IBOutlet weak var enterButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // ✅ для UI-тестов
        enterButton.accessibilityIdentifier = "Authenticate"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowWebViewSegueIdentifier {
            guard let webVC = segue.destination as? WebViewViewController else {
                fatalError("Failed to prepare for \(ShowWebViewSegueIdentifier)")
            }
            webVC.modalPresentationStyle = .fullScreen
            webVC.delegate = self

            // Wire Presenter + Helper
            let authHelper = AuthHelper()
            let presenter = WebViewPresenter(authHelper: authHelper)
            webVC.presenter = presenter
            presenter.view = webVC
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    func makeDelegate(_ delegate: AuthViewControllerDelegate) {
        self.delegate = delegate
    }
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        dismiss(animated: true)
    }

    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        UIBlockingProgressHUD.show()
        oauth2Service.fetchOAuthToken(code: code) { [weak self] result in
            guard let self = self else { return }
            UIBlockingProgressHUD.dismiss()

            switch result {
            case .success:
                self.dismiss(animated: false) {
                    self.delegate?.didAuthenticate(self, success: true)
                }

            case .failure(let error):
                debugPrint("[AuthViewController.fetchToken]: \(error.localizedDescription) code=\(code)")
                self.showAuthErrorAlert()
            }
        }
    }
}

// MARK: - Alerts
private extension AuthViewController {
    func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

