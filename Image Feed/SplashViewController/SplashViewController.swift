import UIKit
import SwiftKeychainWrapper

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

        if let token = oauth2TokenStorage.token, !token.isEmpty {
            fetchProfileAndProceed(with: token)
        } else {
            switchToAuthViewController()
        }
    }

    // MARK: - UI setup

    private func setupSplashVC() {
        view.backgroundColor = .ypBlack
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
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }

        let tabBarController = TabBarController()
        tabBarController.awakeFromNib()
        window.rootViewController = tabBarController
    }

    // MARK: - Profile loading

    private func fetchProfileAndProceed(with token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile(token) { [weak self] result in
            guard let self = self else { return }
            UIBlockingProgressHUD.dismiss()

            switch result {
            case .success:
                guard let username = self.profileService.profile?.username else {
                    debugPrint("[SplashViewController]: profile.username is nil")
                    self.switchToTabBarViewController()
                    return
                }

                    self.profileImageService.fetchProfileImageURL(username: username) { _ in }

                    DispatchQueue.main.async {
                        self.switchToTabBarViewController()
                    }

            case .failure(let error):
                debugPrint("[SplashViewController.fetchProfile]: \(error.localizedDescription)")
                self.switchToAuthViewController()
            }
        }
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController, success: Bool) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if success, let token = self.oauth2TokenStorage.token {
                self.fetchProfileAndProceed(with: token)
            } else {
                self.switchToAuthViewController()
            }
        }
    }
}

