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

    @MainActor
    func testScheduleAdditionSucceedsWhenReloadSucceeds() {
        let repository = TourRepositoryStub()
        let viewModel = TourListViewModel(repository: repository)
        let tour = makeTour()

        let result = viewModel.addScheduleItem(
            to: tour,
            type: .transportation,
            title: "新幹線",
            startDate: tour.startDate,
            endDate: tour.startDate.addingTimeInterval(3600),
            departureLocation: "東京",
            arrivalLocation: "大阪",
            reservationNumber: "",
            notes: ""
        )

        XCTAssertTrue(result)
        XCTAssertEqual(repository.addedScheduleItems.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testScheduleAdditionFailsWhenReloadFails() {
        let repository = TourRepositoryStub()
        repository.failFetchAfterMutation = true
        let viewModel = TourListViewModel(repository: repository)
        let tour = makeTour()

        let result = viewModel.addScheduleItem(
            to: tour,
            type: .accommodation,
            title: "ホテル",
            startDate: tour.startDate,
            endDate: tour.endDate,
            departureLocation: "",
            arrivalLocation: "",
            reservationNumber: "ABC123",
            notes: ""
        )

        XCTAssertFalse(result)
        XCTAssertEqual(repository.addedScheduleItems.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    @MainActor
    func testScheduleUpdateFailsWhenReloadFails() {
        let repository = TourRepositoryStub()
        repository.failFetchAfterMutation = true
        let viewModel = TourListViewModel(repository: repository)
        let tour = makeTour()
        let item = TourScheduleItem(
            type: .transportation,
            title: "電車",
            startDate: tour.startDate,
            endDate: tour.startDate.addingTimeInterval(3600),
            tour: tour
        )

        let result = viewModel.updateScheduleItem(
            item,
            type: .transportation,
            title: "新幹線",
            startDate: item.startDate,
            endDate: item.endDate,
            departureLocation: "東京",
            arrivalLocation: "大阪",
            reservationNumber: "",
            notes: ""
        )

        XCTAssertFalse(result)
        XCTAssertEqual(repository.updatedScheduleItems.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    @MainActor
    func testScheduleDeletionFailsWhenReloadFails() {
        let repository = TourRepositoryStub()
        repository.failFetchAfterMutation = true
        let viewModel = TourListViewModel(repository: repository)
        let tour = makeTour()
        let item = TourScheduleItem(
            type: .accommodation,
            title: "ホテル",
            startDate: tour.startDate,
            endDate: tour.endDate,
            tour: tour
        )

        let result = viewModel.deleteScheduleItem(item)

        XCTAssertFalse(result)
        XCTAssertEqual(repository.deletedScheduleItems.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    private func makeTour() -> TourPlan {
        let startDate = Date()
        return TourPlan(
            title: "テストツアー",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(86400)
        )
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

@MainActor
private final class TourRepositoryStub: TourRepository {
    var failFetchAfterMutation = false
    private var shouldFailFetch = false
    var addedScheduleItems: [TourScheduleItem] = []
    var updatedScheduleItems: [TourScheduleItem] = []
    var deletedScheduleItems: [TourScheduleItem] = []

    func fetchTours() throws -> [TourPlan] {
        if shouldFailFetch {
            throw NSError(
                domain: "TourRepositoryStub",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "再読み込みに失敗しました。"]
            )
        }
        return []
    }

    func add(_ tour: TourPlan) throws {
        prepareFetchResult()
    }

    func update(
        _ tour: TourPlan,
        replacingScheduleItems scheduleItems: [TourScheduleItem]
    ) throws {
        prepareFetchResult()
    }

    func delete(_ tour: TourPlan) throws {
        prepareFetchResult()
    }

    func addScheduleItem(_ item: TourScheduleItem, to tour: TourPlan) throws {
        addedScheduleItems.append(item)
        prepareFetchResult()
    }

    func updateScheduleItem(_ item: TourScheduleItem) throws {
        updatedScheduleItems.append(item)
        prepareFetchResult()
    }

    func deleteScheduleItem(_ item: TourScheduleItem) throws {
        deletedScheduleItems.append(item)
        prepareFetchResult()
    }

    private func prepareFetchResult() {
        shouldFailFetch = failFetchAfterMutation
    }
}
