@testable import Image_Feed
import Foundation

final class WebViewPresenterSpy: WebViewPresenterProtocol {
    // MARK: - Protocol conformance
    weak var view: WebViewViewControllerProtocol?

    // MARK: - Captured values / flags
    private(set) var viewDidLoadCalled = false
    private(set) var didUpdateProgressValues: [Double] = []
    var stubbedRequest: URLRequest?
    var stubbedCode: String?

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func didUpdateProgressValue(_ newValue: Double) {
        didUpdateProgressValues.append(newValue)
    }

    func makeRequest() -> URLRequest? {
        stubbedRequest
    }

    func code(from url: URL) -> String? {
        stubbedCode
    }
}

