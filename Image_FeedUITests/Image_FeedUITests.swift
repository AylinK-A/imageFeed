import XCTest
import UIKit

private enum ID {
    enum Auth {
        static let button = "Authenticate"
        static let webView = "UnsplashWebView"
        static let loginPrimary = "Login"
        static let loginAlt    = "Log in"
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

    private let email = "aylinkyz.1@gmail.com"
    private let pass  = "Leochka123"

    override func setUpWithError() throws {
        continueAfterFailure = false

        app.launchEnvironment["AppleLanguages"] = "(en)"
        app.launchEnvironment["AppleLocale"] = "en_US"

        app.launchArguments = ["-UITests"]
        app.launch()
    }

    // MARK: - Tests

    func testAuth() throws {
        relaunch(with: ["-UITests", "-ResetAuth"])
        try loginFlow_NoEnter_PasteOnly()
        XCTAssertTrue(waitFeedAppeared(timeout: 45), "Лента не появилась после авторизации")
    }

    func testFeed() throws {
        try ensureLoggedIn()

        if !app.tables[ID.Feed.table].waitForExistence(timeout: 10) {
            if app.buttons[ID.Auth.button].exists && app.buttons[ID.Auth.button].isHittable {
                try loginFlow_NoEnter_PasteOnly()
            }
            XCTAssertTrue(waitFeedAppeared(timeout: 30), "Экран ленты не открылся")
        }

        let table = app.tables[ID.Feed.table]
        XCTAssertTrue(table.exists, "Экран ленты не открылся")

        let firstCell = table.cells.element(boundBy: 0)
        if !firstCell.waitForExistence(timeout: 30) {
            table.swipeUp()
            XCTAssertTrue(table.cells.element(boundBy: 0).waitForExistence(timeout: 10),
                          "Контент ленты долго не приходит")
        }

        let cell = table.cells.element(boundBy: 0)
        let like = cell.buttons[ID.Feed.like]
        XCTAssertTrue(like.waitForExistence(timeout: 5), "Кнопка лайка не найдена")
        like.tap()
        usleep(300_000)
        like.tap()

        cell.tap()

        let full = app.images[ID.Feed.fullImage]
        XCTAssertTrue(full.waitForExistence(timeout: 15), "Полноэкранное изображение не открылось")

        full.pinch(withScale: 3.0, velocity: 1.0)
        full.pinch(withScale: 0.5, velocity: -1.0)

        returnToFeed(from: full, table: table)

        XCTAssertTrue(table.waitForExistence(timeout: 15), "Не вернулись на экран ленты")
    }

    func testProfile() throws {
        try ensureLoggedIn()

        let table = app.tables[ID.Feed.table]
        XCTAssertTrue(table.waitForExistence(timeout: 30), "Экран ленты не открылся")

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
        if !webView.waitForExistence(timeout: 15) {
            XCTAssertTrue(waitFeedAppeared(timeout: 30), "Лента не появилась после тапа Authenticate")
            return
        }

        tapIfExists(webView.buttons["Accept"])
        tapIfExists(webView.buttons["Accept all"])
        tapIfExists(webView.buttons["Allow"])

        // Ввод email
        let emailField = webView.textFields.element(boundBy: 0)
        XCTAssertTrue(emailField.waitForExistence(timeout: 12), "Поле e-mail не найдено")
        robustPaste(email, into: emailField, scroller: webView)

        // Снять фокус и проскроллить к паролю
        tapBlankCenter(in: webView)
        webView.swipeUp()
        usleep(150_000)

        // Ввод пароля
        let passwordField = webView.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(passwordField.waitForExistence(timeout: 12), "Поле пароля не найдено")
        focusElement(passwordField, scroller: webView)
        robustPaste(pass, into: passwordField, scroller: webView)

        if !pressKeyboardSubmitIfAvailable() {
            for _ in 0..<2 { webView.swipeUp() }

            let labels = [ID.Auth.loginPrimary, ID.Auth.loginAlt]
            var tapped = false
            for label in labels where !tapped {
                let btn  = webView.buttons[label]
                let link = webView.links[label]
                let txt  = webView.staticTexts[label]
                if btn.exists || link.exists || txt.exists {
                    let el = [btn, link, txt].first { $0.exists && $0.isHittable }
                         ?? [btn, link, txt].first { $0.exists }
                    if let el = el {
                        if el.isHittable { el.tap() }
                        else { el.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap() }
                        tapped = true
                    }
                }
            }

            if !tapped {
                let below = passwordField.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 2.2))
                below.tap()
            }
        }

        let allow = ["Authorize","Allow access","Grant access","Allow","Continue"]
            .map { webView.buttons[$0].firstMatch }
            .first { $0.waitForExistence(timeout: 3) && $0.isHittable }
        allow?.tap()

        let gone = NSPredicate(format: "exists == false")
        let exp = expectation(for: gone, evaluatedWith: webView, handler: nil)
        wait(for: [exp], timeout: 20.0)

        XCTAssertTrue(waitFeedAppeared(timeout: 60), "Лента не появилась после авторизации")
    }

    private func ensureLoggedIn() throws {
        if waitFeedAppeared(timeout: 5) { return }

        let authBtn = app.buttons[ID.Auth.button]
        if authBtn.waitForExistence(timeout: 3), authBtn.isHittable {
            try loginFlow_NoEnter_PasteOnly()
            XCTAssertTrue(waitFeedAppeared(timeout: 60), "Лента не появилась после авторизации")
            return
        }

        XCTAssertTrue(waitFeedAppeared(timeout: 30), "Лента не появилась (ожидали автологин по токену)")
    }

    // MARK: - Wait helpers
    private func waitFeedAppeared(timeout: TimeInterval) -> Bool {
        app.tables[ID.Feed.table].waitForExistence(timeout: timeout)
    }

    // MARK: - UI helpers
    private func relaunch(with args: [String]) {
        app.terminate()
        app.launchArguments = args
        app.launchEnvironment["AppleLanguages"] = "(en)"
        app.launchEnvironment["AppleLocale"] = "en_US"
        app.launch()
    }

    private func tapBlankCenter(in scroller: XCUIElement) {
        let center = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        center.tap()
        usleep(120_000)
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

    private func pressKeyboardSubmitIfAvailable() -> Bool {
        let keys = ["Go","Continue","Done","Return"].map { app.keyboards.buttons[$0] }
        if let key = keys.first(where: { $0.waitForExistence(timeout: 0.8) && $0.isHittable }) {
            key.tap()
            return true
        }
        return false
    }

    private func robustPaste(_ text: String, into field: XCUIElement, scroller: XCUIElement) {
        UIPasteboard.general.string = text

        var tries = 0
        while !field.isHittable && tries < 6 { scroller.swipeUp(); tries += 1 }

        if field.isHittable {
            field.tap()
        } else {
            let coord = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coord.tap()
        }

        _ = app.keyboards.firstMatch.waitForExistence(timeout: 8)

        let coord = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coord.press(forDuration: 0.8)

        let pasteRU = app.menuItems["Вставить"]
        let pasteEN = app.menuItems["Paste"]

        if pasteRU.waitForExistence(timeout: 1.0), pasteRU.isHittable {
            pasteRU.tap(); return
        } else if pasteEN.waitForExistence(timeout: 1.0), pasteEN.isHittable {
            pasteEN.tap(); return
        }

        if !app.keyboards.firstMatch.exists { field.tap() }
        for ch in text {
            field.typeText(String(ch))
            usleep(60_000)
        }
    }

    private func tapIfExists(_ element: XCUIElement) {
        if element.exists && element.isHittable { element.tap() }
    }

    // MARK: - Fullscreen exit helper
    private func returnToFeed(from fullImage: XCUIElement, table: XCUIElement) {
        let candidates: [XCUIElement] = [
            app.buttons["Back"],
            app.buttons["Close"],
            app.navigationBars.buttons.element(boundBy: 0),
            app.buttons.firstMatch
        ]
        if let b = candidates.first(where: { $0.exists && $0.isHittable }) {
            b.tap()
            _ = table.waitForExistence(timeout: 10)
            if table.exists { return }
        }

        if fullImage.exists {
            fullImage.swipeDown()
            if table.waitForExistence(timeout: 10) { return }
        }
        
        app.swipeRight()
        _ = table.waitForExistence(timeout: 10)
    }
}

