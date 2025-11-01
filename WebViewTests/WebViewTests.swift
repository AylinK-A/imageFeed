@testable import Image_Feed
import XCTest

final class WebViewTests: XCTestCase {

    func testViewControllerCallsViewDidLoad() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "WebViewViewController") as! WebViewViewController
        let presenter = WebViewPresenterSpy()
        vc.presenter = presenter
        presenter.view = vc

        _ = vc.view

        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    func testPresenterCallsLoadRequest() {
        let spyView = WebViewViewControllerSpy()
        let presenter = WebViewPresenter(authHelper: AuthHelper())
        presenter.view = spyView

        presenter.viewDidLoad()

        XCTAssertTrue(spyView.loadRequestCalled)
    }

    func testProgressVisibleWhenLessThenOne() {
        let presenter = WebViewPresenter(authHelper: AuthHelper())
        let result = presenter.shouldHideProgress(for: 0.6)
        XCTAssertFalse(result)
    }

    func testProgressHiddenWhenOne() {
        let presenter = WebViewPresenter(authHelper: AuthHelper())
        let result = presenter.shouldHideProgress(for: 1.0)
        XCTAssertTrue(result)
    }

    func testAuthHelperAuthURL() {
        let configuration = AuthConfiguration.standard
        let helper = AuthHelper(configuration: configuration)

        guard let url = helper.authURL() else {
            XCTFail("authURL is nil")
            return
        }
        let urlString = url.absoluteString

        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }

    func testCodeFromURL() {
        let helper = AuthHelper(configuration: .standard)
        var components = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        components.queryItems = [URLQueryItem(name: "code", value: "test code")]
        let url = components.url!

        let code = helper.code(from: url)

        XCTAssertEqual(code, "test code")
    }
}

