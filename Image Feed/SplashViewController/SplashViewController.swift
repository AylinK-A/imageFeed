import UIKit
import WebKit

final class SplashViewController: UIViewController {
    private let oauth2TokenStorage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSplashVC()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if presentedViewController != nil { return }

        if ProcessInfo.processInfo.arguments.contains("-ResetAuth") {
            oauth2TokenStorage.removeAllTokensForUITests()
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                WKWebsiteDataStore.default().removeData(
                    ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                    for: records,
                    completionHandler: {}
                )
            }
        }

        if let token = oauth2TokenStorage.token, !token.isEmpty {
            fetchProfileAndProceed(with: token)
        } else {
            switchToAuthViewController()
        }
    }

    // MARK: - UI setup

    private func setupSplashVC() {
        view.backgroundColor = .black
        let logoImageView = UIImageView(image: UIImage(named: "Logo_of_Unsplash"))
        logoImageView.backgroundColor = .clear
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Navigation

    private func switchToAuthViewController() {
        guard let authVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            assertionFailure("AuthViewController not found")
            return
        }
        authVC.makeDelegate(self)
        authVC.modalPresentationStyle = .fullScreen
        authVC.modalTransitionStyle = .crossDissolve
        present(authVC, animated: true)
    }

    private func switchToTabBarViewController() {
        let tabBarController = TabBarController()
        tabBarController.awakeFromNib()

        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = scene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: nil)
        } else if let window = UIApplication.shared.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }

    // MARK: - Profile loading

    private func fetchProfileAndProceed(with token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile(token) { [weak self] result in
            guard let self else { return }
            UIBlockingProgressHUD.dismiss()

            switch result {
            case .success:
                if let username = self.profileService.profile?.username {
                    self.profileImageService.fetchProfileImageURL(username: username) { _ in }
                }
                DispatchQueue.main.async {
                    self.switchToTabBarViewController()
                }

            case .failure(let error):
                // КЛЮЧЕВОЕ ИЗМЕНЕНИЕ:
                // Если есть токен, но профиль не загрузился — НЕ возвращаем на авторизацию.
                // Идём в основной поток (лента), профиль подгрузится/почините отдельно.
                debugPrint("[SplashViewController.fetchProfile]: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.switchToTabBarViewController()
                }
            }
        }
    }
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController, success: Bool) {
        if success, let token = self.oauth2TokenStorage.token {
            self.fetchProfileAndProceed(with: token)
        } else {
            self.switchToAuthViewController()
        }
    }
}

