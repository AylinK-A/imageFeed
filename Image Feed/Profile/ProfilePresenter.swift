import Foundation
import UIKit

// MARK: - View Protocol
protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfilePresenterProtocol? { get set }
    func show(profile: ProfileViewModel)
    func setAvatar(url: URL?)
    func showLogoutConfirm()
}

// MARK: - Presenter Protocol
protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
}

// MARK: - Dependencies
protocol ProfileProviding {
    var profile: Profile? { get }
}

protocol ProfileImageProviding {
    var avatarURL: String? { get }
    static var didChangeNotification: Notification.Name { get }
}

protocol ProfileLoggingOut {
    func logout()
}

// MARK: - ViewModel
struct ProfileViewModel {
    let name: String
    let login: String
    let bio: String
}

// MARK: - Presenter
final class ProfilePresenter: ProfilePresenterProtocol {

    weak var view: ProfileViewControllerProtocol?

    private let profileService: ProfileProviding
    private let imageServiceType: ProfileImageProviding.Type
    private let imageService: ProfileImageProviding
    private let logoutService: ProfileLoggingOut
    private var profileImageObserver: NSObjectProtocol?

    init(profileService: ProfileProviding,
         imageServiceType: ProfileImageProviding.Type,
         imageService: ProfileImageProviding,
         logoutService: ProfileLoggingOut) {
        self.profileService = profileService
        self.imageServiceType = imageServiceType
        self.imageService = imageService
        self.logoutService = logoutService
    }

    deinit {
        if let o = profileImageObserver {
            NotificationCenter.default.removeObserver(o)
        }
    }

    func viewDidLoad() {
        if let p = profileService.profile {
            let vm = ProfileViewModel(
                name: p.name ?? "—",
                login: p.loginName ?? "—",
                bio: p.bio ?? ""
            )
            view?.show(profile: vm)
        }

        setAvatarFromService()

        profileImageObserver = NotificationCenter.default.addObserver(
            forName: imageServiceType.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setAvatarFromService()
        }
    }

    func didTapLogout() {
        view?.showLogoutConfirm()
    }

    private func setAvatarFromService() {
        if let s = imageService.avatarURL, let url = URL(string: s) {
            view?.setAvatar(url: url)
        } else {
            view?.setAvatar(url: nil)
        }
    }
}

