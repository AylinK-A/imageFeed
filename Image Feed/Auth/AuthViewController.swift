import UIKit
import ProgressHUD

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"

    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage()
    weak var delegate: AuthViewControllerDelegate?

    @IBOutlet private weak var enterButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        enterButton.accessibilityIdentifier = A11yID.Auth.authenticateButton
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard let webVC = segue.destination as? WebViewViewController else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }

            webVC.modalPresentationStyle = .fullScreen
            webVC.delegate = self

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
        presentingViewController?.dismiss(animated: true)
    }

    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        UIBlockingProgressHUD.show()
        oauth2Service.fetchOAuthToken(code: code) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                UIBlockingProgressHUD.dismiss()

                switch result {
                case .success:
                    let delegate = self.delegate
                    let controller = self
                    let presenter = self.presentingViewController

                    presenter?.dismiss(animated: true) {
                        delegate?.didAuthenticate(controller, success: true)
                    }

                case .failure(let error):
                    debugPrint("[AuthViewController.fetchToken] \(error.localizedDescription) code=\(code)")
                    self.showAuthErrorAlert()
                }
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

