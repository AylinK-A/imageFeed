@testable import Image_Feed
import Foundation

final class ProfileViewSpy: ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?

    private(set) var lastVM: ProfileViewModel?
    private(set) var lastAvatarURL: URL?
    private(set) var didShowLogoutConfirm = false

    func show(profile: ProfileViewModel) { lastVM = profile }
    func setAvatar(url: URL?) { lastAvatarURL = url }
    func showLogoutConfirm() { didShowLogoutConfirm = true }
}

