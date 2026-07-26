import XCTest

final class EventUITests: EventTourPlannerUITestCase {
    func testAddEventAndOpenDetail() {
        tapButton("event.addButton")
        enterText("東京ライブ", in: "event.titleField")
        enterText("東京ドーム", in: "event.venueField")

        tapButton("event.saveButton")

        let eventTitle = app.staticTexts["東京ライブ"]
        XCTAssertTrue(eventTitle.waitForExistence(timeout: 5))
        eventTitle.tap()

        XCTAssertTrue(
            app.navigationBars["イベント詳細"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            app.staticTexts["event.detail.venue"].label,
            "会場、東京ドーム"
        )
    }
}
