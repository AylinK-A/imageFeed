@testable import Image_Feed
import Foundation

final class ProfileServiceStub: ProfileProviding {
    var profile: Profile?
    init(profile: Profile? = nil) { self.profile = profile }
}

final class ProfileImageServiceStub: ProfileImageProviding {
    static var didChangeNotification = Notification.Name("ProfileImageServiceStub.didChange")
    var avatarURL: String?
    init(avatarURL: String?) { self.avatarURL = avatarURL }
}

final class LogoutServiceStub: ProfileLoggingOut {
    private(set) var didLogout = false
    func logout() { didLogout = true }
}

