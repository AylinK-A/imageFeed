import XCTest
import UIKit

private enum ID {
    enum Auth {
        static let button = "Authenticate"
        static let webView = "UnsplashWebView"
        static let loginPrimary = "Login"
        static let loginAlt = "Log in"
        static let continueBtn = "Continue"
    }
    enum Feed {
        static let table = "ImagesTable"
        static let like = "LikeButton"
        static let fullImage = "SingleImageView"
    }
    enum Profile {
        static let name = "ProfileName"
        static let login = "ProfileLogin"
        static let bio = "ProfileBio"
        static let logout = "Logout"
        static let confirmYesRU = "Да"
    }
}

final class Image_FeedUITests: XCTestCase {

    private let app = XCUIApplication()

    // ЧТО вводим
    private let email = "aylinkyz.1@gmail.com"
    private let pass  = "Leochka123"

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITests"]
        app.launch()
    }

    // MARK: - Tests

    func testAuth() throws {
        // стартуем в "чистом" состоянии авторизации
        relaunch(with: ["-UITests", "-ResetAuth"])
        try loginFlow_NoEnter_PasteOnly()
        XCTAssertTrue(waitFeedAppeared(timeout: 45), "Лента не появилась после авторизации")
    }

    func testFeed() throws {
        try ensureLoggedIn()

        let table = app.tables[ID.Feed.table]
        XCTAssertTrue(table.waitForExistence(timeout: 30), "Экран ленты не открылся")

        // дожидаемся появления контента
        let firstCell = table.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 30), "Контент ленты долго не приходит")

        table.swipeUp()
        usleep(300_000)

        let like = firstCell.buttons[ID.Feed.like]
        XCTAssertTrue(like.waitForExistence(timeout: 5), "Кнопка лайка не найдена")
        like.tap()
        usleep(300_000)
        like.tap()

        firstCell.tap()

        let full = app.images[ID.Feed.fullImage]
        XCTAssertTrue(full.waitForExistence(timeout: 15), "Полноэкранное изображение не открылось")

        full.pinch(withScale: 3.0, velocity: 1.0)
        full.pinch(withScale: 0.5, velocity: -1.0)

        // вернуться назад
        if app.buttons.firstMatch.exists { app.buttons.firstMatch.tap() }

        XCTAssertTrue(table.waitForExistence(timeout: 10), "Не вернулись на экран ленты")
    }

    func testProfile() throws {
        try ensureLoggedIn()

        let table = app.tables[ID.Feed.table]
        XCTAssertTrue(table.waitForExistence(timeout: 30), "Экран ленты не открылся")

        // Перейти на вкладку профиля (вторая кнопка TabBar)
        let profileTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Вкладка Профиль не найдена")
        profileTab.tap()

        XCTAssertTrue(app.staticTexts[ID.Profile.name].waitForExistence(timeout: 10), "Имя профиля не отображается")
        XCTAssertTrue(app.staticTexts[ID.Profile.login].exists, "Логин профиля не отображается")
        XCTAssertTrue(app.staticTexts[ID.Profile.bio].exists, "Bio профиля не отображается")

        let logoutBtn = app.buttons[ID.Profile.logout]
        XCTAssertTrue(logoutBtn.waitForExistence(timeout: 5), "Кнопка Logout не найдена")
        logoutBtn.tap()

        let yes = app.alerts.buttons[ID.Profile.confirmYesRU]
        XCTAssertTrue(yes.waitForExistence(timeout: 5), "Алерт выхода не появился")
        yes.tap()

        XCTAssertTrue(app.buttons[ID.Auth.button].waitForExistence(timeout: 20), "Экран авторизации не показался")
    }

    // MARK: - Login flow

    private func loginFlow_NoEnter_PasteOnly() throws {
        let authButton = app.buttons[ID.Auth.button]
        XCTAssertTrue(authButton.waitForExistence(timeout: 10), "Кнопка Authenticate не найдена")
        authButton.tap()

        let webView = app.webViews[ID.Auth.webView]
        XCTAssertTrue(webView.waitForExistence(timeout: 25), "Экран авторизации не появился")

        // cookie/consent кнопки — если есть, тапнем
        tapIfExists(webView.buttons["Accept"])
        tapIfExists(webView.buttons["Accept all"])
        tapIfExists(webView.buttons["Allow"])
        tapIfExists(webView.buttons["Я согласен"])

        // e-mail
        let emailField = webView.textFields.element(boundBy: 0)
        XCTAssertTrue(emailField.waitForExistence(timeout: 12), "Поле e-mail не найдено")
        robustPaste(email, into: emailField, scroller: webView)

        // убираем фокус, скроллим к паролю
        tapBlankCenter(in: webView)
        webView.swipeUp()
        usleep(300_000)

        // пароль
        let passwordField = webView.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(passwordField.waitForExistence(timeout: 12), "Поле пароля не найдено")
        focusElement(passwordField, scroller: webView)
        robustPaste(pass, into: passwordField, scroller: webView)

        // submit
        if webView.buttons[ID.Auth.loginAlt].exists { webView.buttons[ID.Auth.loginAlt].tap() }
        else if webView.buttons[ID.Auth.loginPrimary].exists { webView.buttons[ID.Auth.loginPrimary].tap() }
        else if webView.buttons[ID.Auth.continueBtn].exists { webView.buttons[ID.Auth.continueBtn].tap() }
        else if let anyBtn = webView.descendants(matching: .button).allElementsBoundByIndex.first(where: { $0.isHittable }) {
            anyBtn.tap()
        }

        // доп. подтверждение доступа, если появляется
        let authCandidates = ["Authorize","Allow access","Grant access","Allow","Разрешить","Continue","Продолжить"]
        if let allow = authCandidates
            .map({ webView.buttons[$0].firstMatch })
            .first(where: { $0.waitForExistence(timeout: 3) && $0.isHittable }) {
            allow.tap()
        }

        // ждём закрытия webview
        XCTAssertTrue(waitUntilGone(webView, timeout: 20), "WebView не закрылся после логина — редирект не обработан")
    }

    private func ensureLoggedIn() throws {
        // Если виден экран авторизации — логинимся
        if app.buttons[ID.Auth.button].waitForExistence(timeout: 1) {
            try loginFlow_NoEnter_PasteOnly()
            XCTAssertTrue(waitFeedAppeared(timeout: 60), "Лента не появилась после авторизации")
        }
    }

    // MARK: - Wait helpers

    private func waitFeedAppeared(timeout: TimeInterval) -> Bool {
        return app.tables[ID.Feed.table].waitForExistence(timeout: timeout)
    }

    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let start = Date()
        while element.exists && Date().timeIntervalSince(start) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return !element.exists
    }

    // MARK: - UI helpers

    private func relaunch(with args: [String]) {
        app.terminate()
        app.launchArguments = args
        app.launch()
    }

    private func tapBlankCenter(in scroller: XCUIElement) {
        let center = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)) // высоко, чтобы не триггерить Return
        center.tap()
        usleep(250_000)
    }

    private func focusElement(_ element: XCUIElement, scroller: XCUIElement) {
        var tries = 0
        while !element.isHittable && tries < 8 {
            scroller.swipeUp(); tries += 1
        }
        if element.isHittable { element.tap() }
        if app.keyboards.firstMatch.waitForExistence(timeout: 1.0) { return }

        if element.isHittable { element.doubleTap() }
        if app.keyboards.firstMatch.waitForExistence(timeout: 1.0) { return }

        let center = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 1.0)
    }

    private func robustPaste(_ text: String, into field: XCUIElement, scroller: XCUIElement) {
        UIPasteboard.general.string = text

        var tries = 0
        while !field.isHittable && tries < 8 {
            scroller.swipeUp(); tries += 1
        }

        if field.isHittable { field.tap() } else {
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 1.0)

        let points: [CGVector] = [
            .init(dx: 0.5, dy: 0.5),
            .init(dx: 0.85, dy: 0.5),
            .init(dx: 0.15, dy: 0.5)
        ]

        func tryPasteMenu() -> Bool {
            let ru = app.menuItems["Вставить"]
            let en = app.menuItems["Paste"]
            if ru.waitForExistence(timeout: 1.2), ru.isHittable { ru.tap(); return true }
            if en.waitForExistence(timeout: 1.2), en.isHittable { en.tap(); return true }
            return false
        }

        func trySelectAll() -> Bool {
            let ru = app.menuItems["Выбрать все"]
            let en = app.menuItems["Select All"]
            if ru.waitForExistence(timeout: 0.8) { ru.tap(); return true }
            if en.waitForExistence(timeout: 0.8) { en.tap(); return true }
            return false
        }

        for p in points {
            let coord = field.coordinate(withNormalizedOffset: p)
            coord.press(forDuration: 0.8)
            if tryPasteMenu() { return }
            if trySelectAll() {
                coord.press(forDuration: 0.7)
                if tryPasteMenu() { return }
            }
        }

        // fallback: если нет контекстного меню, но есть клавиатура — печатаем
        if app.keyboards.firstMatch.exists {
            field.typeText(text)
            return
        }

        XCTFail("Меню вставки не появилось и клавиатуры нет — некуда вводить текст")
    }

    private func tapIfExists(_ element: XCUIElement) {
        if element.exists && element.isHittable { element.tap() }
    }
}

