import XCTest
import SwiftData
@testable import EventTourPlanner

final class TourScheduleTests: XCTestCase {
    func testScheduleDatesAreClampedWhenTourPeriodIsShortened() {
        let calendar = Calendar(identifier: .gregorian)
        let tourStart = date(2026, 8, 1, 0, 0, calendar: calendar)
        let tourEnd = date(2026, 8, 2, 0, 0, calendar: calendar)
        let originalStart = date(2026, 8, 5, 10, 0, calendar: calendar)
        let originalEnd = date(2026, 8, 5, 12, 0, calendar: calendar)

        let result = TourScheduleDateRange.clampedDates(
            startDate: originalStart,
            endDate: originalEnd,
            tourStartDate: tourStart,
            tourEndDate: tourEnd,
            calendar: calendar
        )

        let expectedLimit = date(2026, 8, 2, 23, 59, calendar: calendar, second: 59)
        XCTAssertEqual(result.startDate, expectedLimit)
        XCTAssertEqual(result.endDate, expectedLimit)
    }

    func testScheduleEndDateIsNeverBeforeStartDate() {
        let calendar = Calendar(identifier: .gregorian)
        let tourStart = date(2026, 8, 1, 0, 0, calendar: calendar)
        let tourEnd = date(2026, 8, 3, 0, 0, calendar: calendar)
        let start = date(2026, 8, 2, 18, 0, calendar: calendar)
        let end = date(2026, 8, 2, 9, 0, calendar: calendar)

        let result = TourScheduleDateRange.clampedDates(
            startDate: start,
            endDate: end,
            tourStartDate: tourStart,
            tourEndDate: tourEnd,
            calendar: calendar
        )

        XCTAssertEqual(result.startDate, start)
        XCTAssertEqual(result.endDate, start)
    }

    @MainActor
    func testDraftEditorRecognizesEditingMode() {
        let draft = TourScheduleDraft(
            type: .accommodation,
            title: "Hotel",
            startDate: Date(),
            endDate: Date()
        )
        let editor = TourScheduleEditorView(
            draft: draft,
            tourStartDate: Date().addingTimeInterval(-3600),
            tourEndDate: Date().addingTimeInterval(86400),
            onSave: { _ in true }
        )

        XCTAssertTrue(editor.isEditing)
    }

    func testTourExpenseAggregatesLinkedEvents() {
        let event = LiveEvent(
            title: "Live",
            venue: "Tokyo",
            startDate: Date()
        )
        event.expenses = [
            EventExpense(name: "", amount: 12_000, category: .ticket),
            EventExpense(name: "", amount: 8_000, category: .transportation)
        ]
        let tour = TourPlan(
            title: "Tour",
            startDate: Date(),
            endDate: Date(),
            budget: 30_000
        )
        tour.events = [event]

        XCTAssertEqual(tour.totalExpense, 20_000)
        XCTAssertEqual(tour.remainingBudget, 10_000)
        XCTAssertEqual(tour.budgetUsageRate, 2.0 / 3.0, accuracy: 0.0001)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        calendar: Calendar,
        second: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
        )!
    }
}
