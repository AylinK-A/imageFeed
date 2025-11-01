import Foundation

protocol WebViewViewControllerProtocol: AnyObject {
    func load(_ request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

protocol WebViewPresenterProtocol: AnyObject {
    var view: WebViewViewControllerProtocol? { get set }
    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func makeRequest() -> URLRequest?
    func code(from url: URL) -> String?
}

final class WebViewPresenter: WebViewPresenterProtocol {
    weak var view: WebViewViewControllerProtocol?
    private let authHelper: AuthHelperProtocol

    init(authHelper: AuthHelperProtocol = AuthHelper()) {
        self.authHelper = authHelper
    }

    func viewDidLoad() {
        view?.setProgressHidden(false)
        if let request = makeRequest() {
            view?.load(request)
            updateProgress(0.0)
        }
    }

    func makeRequest() -> URLRequest? {
        authHelper.authURLRequest
    }

    func didUpdateProgressValue(_ newValue: Double) {
        updateProgress(newValue)
    }

    func code(from url: URL) -> String? {
        authHelper.getCode(from: url)
    }

    func shouldHideProgress(for value: Double) -> Bool {
        return value >= 1.0 || value.isNaN
    }

    private func updateProgress(_ value: Double) {
        view?.setProgressValue(Float(value))
        view?.setProgressHidden(shouldHideProgress(for: value)) 
    }
}

