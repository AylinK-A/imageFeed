import XCTest
import UIKit

final class Image_FeedUITests: XCTestCase {

    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITests"]
        app.launch()
    }

    func testAuth() throws {
        app.terminate()
        app.launchArguments = ["-UITests", "-ResetAuth"]
        app.launch()

        try loginFlow_NoEnter_PasteOnly()

        XCTAssertTrue(app.tables["ImagesTable"].waitForExistence(timeout: 90),
                      "Лента не появилась после авторизации")
    }

    func testFeed() throws {
        try ensureLoggedIn()

        let table = app.tables["ImagesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 30), "Экран ленты не открылся")

        let firstCell = table.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 60), "Контент ленты долго не приходит")

        table.swipeUp()
        sleep(1)

        let like = firstCell.buttons["LikeButton"]
        XCTAssertTrue(like.waitForExistence(timeout: 5), "Кнопка лайка не найдена")
        like.tap()
        sleep(1)
        like.tap()

        firstCell.tap()

        let full = app.images["SingleImageView"]
        XCTAssertTrue(full.waitForExistence(timeout: 15), "Полноэкранное изображение не открылось")

        full.pinch(withScale: 3.0, velocity: 1.0)
        full.pinch(withScale: 0.5, velocity: -1.0)

        if app.buttons.firstMatch.exists { app.buttons.firstMatch.tap() }

        XCTAssertTrue(table.waitForExistence(timeout: 10), "Не вернулись на ленту")
    }

    func testProfile() throws {
        try ensureLoggedIn()

        let table = app.tables["ImagesTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 30), "Экран ленты не открылся")

        let profileTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Вкладка Профиль не найдена")
        profileTab.tap()

        XCTAssertTrue(app.staticTexts["ProfileName"].waitForExistence(timeout: 10), "Имя профиля не отображается")
        XCTAssertTrue(app.staticTexts["ProfileLogin"].exists, "Логин профиля не отображается")
        XCTAssertTrue(app.staticTexts["ProfileBio"].exists, "Bio профиля не отображается")

        let logoutBtn = app.buttons["Logout"]
        XCTAssertTrue(logoutBtn.waitForExistence(timeout: 5), "Кнопка Logout не найдена")
        logoutBtn.tap()

        let yes = app.alerts.buttons["Да"]
        XCTAssertTrue(yes.waitForExistence(timeout: 5), "Алерт выхода не появился")
        yes.tap()

        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 20),
                      "Экран авторизации не показался")
    }

    private func loginFlow_NoEnter_PasteOnly() throws {
        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 10), "Кнопка Authenticate не найдена")
        authButton.tap()

        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 20), "Экран авторизации не появился")

        tapIfExists(webView.buttons["Accept"])
        tapIfExists(webView.buttons["Accept all"])
        tapIfExists(webView.buttons["Allow"])
        tapIfExists(webView.buttons["Я согласен"])

        let emailField = webView.textFields.element(boundBy: 0)
        XCTAssertTrue(emailField.waitForExistence(timeout: 10), "Поле e-mail не найдено")

        let email = "aylinkyz.1@gmail.com"
        let pass  = "Leochka123"

        robustPaste(email, into: emailField, scroller: webView)

        tapBlankCenter(in: webView)

        webView.swipeUp()
        usleep(300_000)

        let passwordField = webView.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(passwordField.waitForExistence(timeout: 12), "Поле пароля не найдено")
        focusElement(passwordField, scroller: webView)
        robustPaste(pass, into: passwordField, scroller: webView)

        if webView.buttons["Log in"].exists { webView.buttons["Log in"].tap() }
        else if webView.buttons["Login"].exists { webView.buttons["Login"].tap() }
        else if webView.buttons["Continue"].exists { webView.buttons["Continue"].tap() }
        else if let anyBtn = webView.descendants(matching: .button).allElementsBoundByIndex.first(where: { $0.isHittable }) {
            anyBtn.tap()
        }

        let authCandidates = ["Authorize","Allow access","Grant access","Allow","Разрешить","Continue","Продолжить"]
        if let allow = authCandidates
            .map({ webView.buttons[$0].firstMatch })
            .first(where: { $0.waitForExistence(timeout: 3) && $0.isHittable }) {
            allow.tap()
        }

        XCTAssertTrue(waitUntilGone(webView, timeout: 15),
                      "WebView не закрылся после Login/Authorize — редирект не обработан")
    }

    private func ensureLoggedIn() throws {
        if app.buttons["Authenticate"].waitForExistence(timeout: 1) {
            try loginFlow_NoEnter_PasteOnly()
            XCTAssertTrue(app.tables["ImagesTable"].waitForExistence(timeout: 90),
                          "Лента не появилась после авторизации")
        }
    }

    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let start = Date()
        while element.exists && Date().timeIntervalSince(start) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return !element.exists
    }

    private func tapBlankCenter(in scroller: XCUIElement) {
        let center = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.tap()
        usleep(300_000)
    }

    private func focusElement(_ element: XCUIElement, scroller: XCUIElement) {
        var tries = 0
        while !element.isHittable && tries < 6 {
            scroller.swipeUp(); tries += 1
        }
        if element.isHittable { element.tap() }
        if app.keyboards.firstMatch.waitForExistence(timeout: 0.8) { return }

        if element.isHittable { element.doubleTap() }
        if app.keyboards.firstMatch.waitForExistence(timeout: 0.8) { return }

        let center = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 0.8)
    }

    private func robustPaste(_ text: String, into field: XCUIElement, scroller: XCUIElement) {
        UIPasteboard.general.string = text

        var tries = 0
        while !field.isHittable && tries < 8 {
            scroller.swipeUp(); tries += 1
        }

        if field.isHittable { field.tap() } else {
            let c = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            c.tap()
        }
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 1.0)

        let points: [CGVector] = [
            .init(dx: 0.5, dy: 0.5), // center
            .init(dx: 0.85, dy: 0.5), // right
            .init(dx: 0.15, dy: 0.5)  // left
        ]

        func tryPasteMenu() -> Bool {
            let pasteRU = app.menuItems["Вставить"]
            let pasteEN = app.menuItems["Paste"]
            if pasteRU.waitForExistence(timeout: 1.2), pasteRU.isHittable { pasteRU.tap(); return true }
            if pasteEN.waitForExistence(timeout: 1.2), pasteEN.isHittable { pasteEN.tap(); return true }
            return false
        }

        func trySelectAll() -> Bool {
            let selRU = app.menuItems["Выбрать все"]
            let selEN = app.menuItems["Select All"]
            if selRU.waitForExistence(timeout: 0.8) { selRU.tap(); return true }
            if selEN.waitForExistence(timeout: 0.8) { selEN.tap(); return true }
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

        let below = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        below.press(forDuration: 0.8)
        if tryPasteMenu() { return }

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

