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
        XCTAssertEqual(repository.fetchCallCount, 0)
        XCTAssertEqual(tour.scheduleItems.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testScheduleAdditionDoesNotReloadAfterSaving() {
        let repository = TourRepositoryStub()
        repository.fetchError = TourRepositoryStub.reloadError
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

        XCTAssertTrue(result)
        XCTAssertEqual(repository.addedScheduleItems.count, 1)
        XCTAssertEqual(repository.fetchCallCount, 0)
        XCTAssertEqual(tour.scheduleItems.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testScheduleUpdateDoesNotReloadAfterSaving() {
        let repository = TourRepositoryStub()
        repository.fetchError = TourRepositoryStub.reloadError
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

        XCTAssertTrue(result)
        XCTAssertEqual(repository.updatedScheduleItems.count, 1)
        XCTAssertEqual(repository.fetchCallCount, 0)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testScheduleDeletionDoesNotReloadAfterDeleting() {
        let repository = TourRepositoryStub()
        repository.fetchError = TourRepositoryStub.reloadError
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

        XCTAssertTrue(result)
        XCTAssertEqual(repository.deletedScheduleItems.count, 1)
        XCTAssertEqual(repository.fetchCallCount, 0)
        XCTAssertTrue(tour.scheduleItems.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testTourAdditionDoesNotReloadAfterSaving() {
        let repository = TourRepositoryStub()
        repository.fetchError = TourRepositoryStub.reloadError
        let viewModel = TourListViewModel(repository: repository)
        let startDate = Date()

        let result = viewModel.addTour(
            title: "追加ツアー",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(86400),
            budget: 10_000,
            notes: "",
            events: [],
            scheduleItems: []
        )

        XCTAssertTrue(result)
        XCTAssertEqual(repository.addedTours.count, 1)
        XCTAssertEqual(repository.fetchCallCount, 0)
        XCTAssertEqual(viewModel.tours.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testTourUpdateDoesNotReloadAfterSaving() {
        let tour = makeTour()
        let repository = TourRepositoryStub()
        repository.fetchedTours = [tour]
        let viewModel = TourListViewModel(repository: repository)
        XCTAssertTrue(viewModel.loadTours())
        repository.fetchError = TourRepositoryStub.reloadError

        let result = viewModel.updateTour(
            tour,
            title: "更新ツアー",
            startDate: tour.startDate,
            endDate: tour.endDate,
            budget: 20_000,
            notes: "更新",
            events: [],
            scheduleItems: []
        )

        XCTAssertTrue(result)
        XCTAssertEqual(repository.updatedTours.count, 1)
        XCTAssertEqual(repository.fetchCallCount, 1)
        XCTAssertEqual(viewModel.tours.first?.title, "更新ツアー")
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testTourDeletionDoesNotReloadAfterDeleting() {
        let tour = makeTour()
        let repository = TourRepositoryStub()
        repository.fetchedTours = [tour]
        let viewModel = TourListViewModel(repository: repository)
        XCTAssertTrue(viewModel.loadTours())
        repository.fetchError = TourRepositoryStub.reloadError

        viewModel.deleteTour(tour)

        XCTAssertEqual(repository.deletedTours.count, 1)
        XCTAssertEqual(repository.fetchCallCount, 1)
        XCTAssertTrue(viewModel.tours.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
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
    static let reloadError = NSError(
        domain: "TourRepositoryStub",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "再読み込みに失敗しました。"]
    )

    var fetchError: Error?
    var fetchCallCount = 0
    var fetchedTours: [TourPlan] = []
    var addedTours: [TourPlan] = []
    var updatedTours: [TourPlan] = []
    var deletedTours: [TourPlan] = []
    var addedScheduleItems: [TourScheduleItem] = []
    var updatedScheduleItems: [TourScheduleItem] = []
    var deletedScheduleItems: [TourScheduleItem] = []

    func fetchTours() throws -> [TourPlan] {
        fetchCallCount += 1
        if let fetchError {
            throw fetchError
        }
        return fetchedTours
    }

    func add(_ tour: TourPlan) throws {
        addedTours.append(tour)
    }

    func update(
        _ tour: TourPlan,
        replacingScheduleItems scheduleItems: [TourScheduleItem]
    ) throws {
        updatedTours.append(tour)
    }

    func delete(_ tour: TourPlan) throws {
        deletedTours.append(tour)
    }

    func addScheduleItem(_ item: TourScheduleItem, to tour: TourPlan) throws {
        addedScheduleItems.append(item)
    }

    func updateScheduleItem(_ item: TourScheduleItem) throws {
        updatedScheduleItems.append(item)
    }

    func deleteScheduleItem(_ item: TourScheduleItem) throws {
        deletedScheduleItems.append(item)
    }
}
