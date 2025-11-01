@testable import Image_Feed
import XCTest

final class ProfilePresenterTests: XCTestCase {

    func testDidTapLogout_showsConfirm() {
        let view = ProfileViewSpy()
        let presenter = ProfilePresenter(
            profileService: ProfileServiceStub(),
            imageServiceType: ProfileImageServiceStub.self,
            imageService: ProfileImageServiceStub(avatarURL: nil),
            logoutService: LogoutServiceStub()
        )
        presenter.view = view

        presenter.didTapLogout()

        XCTAssertTrue(view.didShowLogoutConfirm)
    }

    func testViewDidLoad_setsAvatarFromService() {
        let view = ProfileViewSpy()
        let presenter = ProfilePresenter(
            profileService: ProfileServiceStub(),
            imageServiceType: ProfileImageServiceStub.self,
            imageService: ProfileImageServiceStub(avatarURL: "https://example.com/a.png"),
            logoutService: LogoutServiceStub()
        )
        presenter.view = view

        presenter.viewDidLoad()

        XCTAssertEqual(view.lastAvatarURL?.absoluteString, "https://example.com/a.png")
    }

    func testNotification_updatesAvatar() {
        let view = ProfileViewSpy()
        let imageService = ProfileImageServiceStub(avatarURL: "https://example.com/1.png")
        let presenter = ProfilePresenter(
            profileService: ProfileServiceStub(),
            imageServiceType: ProfileImageServiceStub.self,
            imageService: imageService,
            logoutService: LogoutServiceStub()
        )
        presenter.view = view

        presenter.viewDidLoad()
        XCTAssertEqual(view.lastAvatarURL?.absoluteString, "https://example.com/1.png")

        imageService.avatarURL = "https://example.com/2.png"
        NotificationCenter.default.post(name: ProfileImageServiceStub.didChangeNotification, object: nil)

        let exp = expectation(description: "avatar updated")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(view.lastAvatarURL?.absoluteString, "https://example.com/2.png")
    }
}

