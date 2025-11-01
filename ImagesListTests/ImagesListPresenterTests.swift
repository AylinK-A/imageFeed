@testable import Image_Feed
import XCTest

final class ImagesListPresenterTests: XCTestCase {

    // 1) При пустом списке на старте презентер просит следующую страницу
    func test_viewDidLoad_fetchesNextPage_whenEmpty() {
        let service = ImagesServiceStub()
        service.setPhotos([])

        let presenter = ImagesListPresenter(service: service)
        let view = ImagesListViewSpy()
        presenter.view = view

        presenter.viewDidLoad()

        XCTAssertTrue(service.didFetchNextPage, "Ожидали fetchNextPage() при пустом списке")
    }

    // 2) Получили новые фото -> вставили хвост строк
    func test_handlePhotosUpdate_insertsTail() {
        let service = ImagesServiceStub()
        service.setPhotos([makePhoto(id: "1")])

        let presenter = ImagesListPresenter(service: service)
        let view = ImagesListViewSpy()
        presenter.view = view

        presenter.viewDidLoad()

        // имитируем загрузку ещё двух фото
        service.setPhotos([makePhoto(id: "1"), makePhoto(id: "2"), makePhoto(id: "3")])
        service.postDidChange()

        // вставки с 1 по 2 (0-based)
        XCTAssertEqual(view.inserted, [IndexPath(row: 1, section: 0), IndexPath(row: 2, section: 0)])
    }

    // 3) toggleLike: дизейблим кнопку, делаем запрос, энэйблим и перерисовываем строку при успехе
    func test_toggleLike_success_flow() {
        let service = ImagesServiceStub()
        service.setPhotos([makePhoto(id: "1", liked: false)])

        let presenter = ImagesListPresenter(service: service)
        let view = ImagesListViewSpy()
        presenter.view = view

        let ip = IndexPath(row: 0, section: 0)
        presenter.toggleLike(at: ip)

        // кнопка выключена → включена
        XCTAssertEqual(view.likeEnabled.first?.0, false)
        XCTAssertEqual(view.likeEnabled.first?.1, ip)

        // completion идёт на main — дождёмся очереди
        let exp = expectation(description: "main")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)

        // повторная запись про включение
        XCTAssertEqual(view.likeEnabled.last?.0, true)
        XCTAssertEqual(view.likeEnabled.last?.1, ip)
        // и перерисовка строки
        XCTAssertTrue(view.reloaded.contains(ip))
        // сервис получил корректные параметры
        XCTAssertEqual(service.likeCalledWith?.id, "1")
        XCTAssertEqual(service.likeCalledWith?.isLike, true)
    }

    // 4) toggleLike: при ошибке показываем алерт
    func test_toggleLike_failure_showsError() {
        enum TestError: Error { case fail }
        let service = ImagesServiceStub()
        service.setPhotos([makePhoto(id: "1", liked: false)])
        service.likeResult = .failure(TestError.fail)

        let presenter = ImagesListPresenter(service: service)
        let view = ImagesListViewSpy()
        presenter.view = view

        let ip = IndexPath(row: 0, section: 0)
        presenter.toggleLike(at: ip)

        let exp = expectation(description: "main")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)

        XCTAssertTrue(view.showLikeErrorCalled)
    }

    // 5) willDisplayCell — при подходе к концу запрашиваем следующую страницу
    func test_willDisplayCell_triggersPagination() {
        let service = ImagesServiceStub()
        service.setPhotos([makePhoto(id: "1"), makePhoto(id: "2"), makePhoto(id: "3")])

        let presenter = ImagesListPresenter(service: service)
        let view = ImagesListViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        XCTAssertFalse(service.didFetchNextPage) // viewDidLoad ничего не просит, т.к. уже не пусто

        presenter.willDisplayCell(at: IndexPath(row: 2, section: 0)) // последний элемент
        XCTAssertTrue(service.didFetchNextPage)
    }
}

