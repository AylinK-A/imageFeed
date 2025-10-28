import Foundation
import UIKit
import WebKit
import SwiftKeychainWrapper

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    private init() {}

    func logout() {
        let tokenStorage = OAuth2TokenStorage()
        tokenStorage.token = nil
        _ = KeychainWrapper.standard.removeObject(forKey: "bearerToken")

        URLCache.shared.removeAllCachedResponses()

        cleanCookies { [weak self] in
            self?.routeToStart()
        }
    }

    private func cleanCookies(completion: @escaping () -> Void) {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            let group = DispatchGroup()
            for record in records {
                group.enter()
                dataStore.removeData(ofTypes: record.dataTypes, for: [record]) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                completion()
            }
        }
    }

    private func routeToStart() {
        DispatchQueue.main.async {
            let window: UIWindow? = UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
                ?? UIApplication.shared.windows.first

            guard let window else {
                assertionFailure("Не найдено активное окно для смены rootViewController")
                return
            }

            let storyboard = UIStoryboard(name: "Main", bundle: .main)

            let startVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController")

            window.rootViewController?.dismiss(animated: false)

            window.rootViewController = startVC
            window.makeKeyAndVisible()

            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: nil,
                completion: nil
            )
        }
    }
}

