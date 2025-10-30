@testable import Image_Feed
import Foundation

final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?
    var loadRequestCalled = false
    var progressValues: [Float] = []
    var isProgressHidden: Bool?

    func load(request: URLRequest) {
        loadRequestCalled = true
    }

    func setProgressValue(_ newValue: Float) {
        progressValues.append(newValue)
    }

    func setProgressHidden(_ isHidden: Bool) {
        isProgressHidden = isHidden
    }
}

