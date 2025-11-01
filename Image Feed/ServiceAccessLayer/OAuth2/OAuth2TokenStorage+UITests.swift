import Foundation
import SwiftKeychainWrapper

extension OAuth2TokenStorage {
    func removeAllTokensForUITests() {
        self.token = nil
        _ = KeychainWrapper.standard.removeObject(forKey: "Auth token")
    }
}

