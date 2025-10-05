import UIKit
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    private let storage: KeychainWrapper = .standard
    private enum Keys: String {
        case bearerToken
    }
    
    var token: String? {
        get {
            storage.string(forKey: Keys.bearerToken.rawValue)
        }
        set {
            storage.set(newValue ?? "", forKey: Keys.bearerToken.rawValue)
        }
    }
}

