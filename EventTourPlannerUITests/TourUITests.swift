import XCTest

final class TourUITests: EventTourPlannerUITestCase {
    func testAddTourWithTransportationScheduleAndOpenDetail() {
        let tourTab = app.tabBars.buttons["ツアー"]
        XCTAssertTrue(tourTab.waitForExistence(timeout: 5))
        tourTab.tap()

        tapButton("tour.addButton")
        enterText("東京遠征", in: "tour.titleField")
        tapButton("tour.schedule.addButton")
        enterText("新幹線", in: "schedule.titleField")
        enterText("東京", in: "schedule.departureField")
        enterText("大阪", in: "schedule.arrivalField")
        tapButton("schedule.saveButton")

        XCTAssertTrue(
            app.staticTexts["新幹線"].waitForExistence(timeout: 5)
        )
        tapButton("tour.saveButton")

        let tourTitle = app.staticTexts["東京遠征"]
        XCTAssertTrue(tourTitle.waitForExistence(timeout: 5))
        tourTitle.tap()

        XCTAssertTrue(
            app.navigationBars["ツアー詳細"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["新幹線"].exists)
        XCTAssertEqual(
            app.staticTexts["tour.detail.scheduleRoute"].label,
            "東京 → 大阪"
        )
    }
}
