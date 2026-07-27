import XCTest

class EventTourPlannerUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "-AppleLanguages", "(ja)",
            "-AppleLocale", "ja_JP"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func tapButton(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    func enterText(_ text: String, in identifier: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        let focusedField = app.textFields.matching(
            NSPredicate(
                format: "identifier == %@ AND hasKeyboardFocus == true",
                identifier
            )
        ).firstMatch

        for _ in 0..<3 where !focusedField.exists {
            field.tap()
            _ = focusedField.waitForExistence(timeout: 1)
        }

        XCTAssertTrue(
            focusedField.exists,
            "\(identifier) にキーボードフォーカスを設定できませんでした。"
        )
        focusedField.typeText(text)
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        let doneButton = app.keyboards.buttons["完了"]
        if doneButton.waitForExistence(timeout: 1) {
            doneButton.tap()
        } else {
            app.navigationBars.firstMatch.tap()
        }
    }
}
