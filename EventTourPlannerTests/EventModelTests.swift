import XCTest
@testable import EventTourPlanner

final class EventModelTests: XCTestCase {
    func testLiveDefaultScheduleUsesExpectedOffsets() {
        let startDate = Date(timeIntervalSince1970: 1_800_000_000)

        XCTAssertEqual(
            EventType.live.defaultMeetupDate(for: startDate),
            startDate.addingTimeInterval(-7200)
        )
        XCTAssertEqual(
            EventType.live.defaultDoorsOpenDate(for: startDate),
            startDate.addingTimeInterval(-3600)
        )
        XCTAssertEqual(
            EventType.live.defaultScheduledEndDate(for: startDate),
            startDate.addingTimeInterval(7200)
        )
    }

    func testEventBudgetCalculationsAggregateExpenses() {
        let event = LiveEvent(
            title: "Live",
            venue: "Tokyo",
            startDate: Date(),
            budget: 30_000
        )
        event.expenses = [
            EventExpense(name: "", amount: 12_000, category: .ticket),
            EventExpense(name: "", amount: 8_000, category: .transportation)
        ]

        XCTAssertEqual(event.totalExpense, 20_000)
        XCTAssertEqual(event.remainingBudget, 10_000)
        XCTAssertEqual(event.budgetUsageRate, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testBudgetUsageRateIsZeroWhenBudgetIsZero() {
        let event = LiveEvent(
            title: "Live",
            venue: "",
            startDate: Date()
        )
        event.expenses = [
            EventExpense(name: "", amount: 1_000, category: .other)
        ]

        XCTAssertEqual(event.budgetUsageRate, 0)
        XCTAssertEqual(event.remainingBudget, -1_000)
    }

    func testUnknownRawValuesUseFallbackCases() {
        let event = LiveEvent(
            title: "Live",
            venue: "",
            startDate: Date()
        )
        event.eventTypeRawValue = "unknown"
        let expense = EventExpense(
            name: "",
            amount: 1_000,
            category: .ticket
        )
        expense.categoryRawValue = "unknown"

        XCTAssertEqual(event.eventType, .live)
        XCTAssertEqual(expense.category, .other)
    }

    func testAllExpenseCategoriesHaveUniqueIdentifiersAndIcons() {
        XCTAssertEqual(
            Set(ExpenseCategory.allCases.map(\.id)).count,
            ExpenseCategory.allCases.count
        )
        XCTAssertTrue(
            ExpenseCategory.allCases.allSatisfy { !$0.systemImage.isEmpty }
        )
    }
}
