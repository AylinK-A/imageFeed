@testable import Image_Feed
import Foundation

final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    private(set) var lastLoadedRequest: URLRequest?
    private(set) var loadRequestCalled = false
    private(set) var progressValues: [Float] = []
    private(set) var isProgressHiddenValues: [Bool] = []


    func load(_ request: URLRequest) {
        lastLoadedRequest = request
        loadRequestCalled = true                      
    }

    func setProgressValue(_ newValue: Float) {
        progressValues.append(newValue)
    }

    func setProgressHidden(_ isHidden: Bool) {
        isProgressHiddenValues.append(isHidden)
    }
}

