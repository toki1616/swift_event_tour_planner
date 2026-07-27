import XCTest
import SwiftData
@testable import EventTourPlanner

@MainActor
final class SwiftDataRepositoryTests: XCTestCase {
    func testEventRepositoryAddsAndFetchesEventsByStartDate() throws {
        let context = try makeContext()
        let repository = SwiftDataEventRepository(modelContext: context)
        let later = LiveEvent(
            title: "Later",
            venue: "",
            startDate: Date(timeIntervalSince1970: 2_000)
        )
        let earlier = LiveEvent(
            title: "Earlier",
            venue: "",
            startDate: Date(timeIntervalSince1970: 1_000)
        )

        try repository.add(later)
        try repository.add(earlier)

        XCTAssertEqual(
            try repository.fetchEvents().map(\.title),
            ["Earlier", "Later"]
        )
    }

    func testEventRepositoryReplacesAndDeletesExpenses() throws {
        let context = try makeContext()
        let repository = SwiftDataEventRepository(modelContext: context)
        let event = LiveEvent(
            title: "Live",
            venue: "",
            startDate: Date()
        )
        let removedExpense = EventExpense(
            name: "交通費",
            amount: 1_000,
            category: .transportation,
            event: event
        )
        event.expenses = [removedExpense]
        try repository.add(event)
        let addedExpense = EventExpense(
            name: "宿泊費",
            amount: 8_000,
            category: .accommodation,
            event: event
        )

        try repository.update(
            event,
            replacingExpenses: [addedExpense]
        )

        let expenses = try context.fetch(FetchDescriptor<EventExpense>())
        XCTAssertEqual(expenses.count, 1)
        XCTAssertEqual(expenses.first?.name, "宿泊費")
        XCTAssertTrue(expenses.first?.event === event)
    }

    func testDeletingEventCascadesExpenses() throws {
        let context = try makeContext()
        let repository = SwiftDataEventRepository(modelContext: context)
        let event = LiveEvent(
            title: "Live",
            venue: "",
            startDate: Date()
        )
        event.expenses = [
            EventExpense(
                name: "",
                amount: 5_000,
                category: .ticket,
                event: event
            )
        ]
        try repository.add(event)

        try repository.delete(event)

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<LiveEvent>()).isEmpty
        )
        XCTAssertTrue(
            try context.fetch(FetchDescriptor<EventExpense>()).isEmpty
        )
    }

    func testTourRepositoryAddsAndFetchesToursByStartDate() throws {
        let context = try makeContext()
        let repository = SwiftDataTourRepository(modelContext: context)
        let later = TourPlan(
            title: "Later",
            startDate: Date(timeIntervalSince1970: 2_000),
            endDate: Date(timeIntervalSince1970: 3_000)
        )
        let earlier = TourPlan(
            title: "Earlier",
            startDate: Date(timeIntervalSince1970: 1_000),
            endDate: Date(timeIntervalSince1970: 2_000)
        )

        try repository.add(later)
        try repository.add(earlier)

        XCTAssertEqual(
            try repository.fetchTours().map(\.title),
            ["Earlier", "Later"]
        )
    }

    func testTourRepositoryReplacesScheduleItems() throws {
        let context = try makeContext()
        let repository = SwiftDataTourRepository(modelContext: context)
        let tour = TourPlan(
            title: "Tour",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400)
        )
        let removedItem = TourScheduleItem(
            type: .transportation,
            title: "電車",
            startDate: tour.startDate,
            endDate: tour.startDate.addingTimeInterval(3600),
            tour: tour
        )
        tour.scheduleItems = [removedItem]
        try repository.add(tour)
        let addedItem = TourScheduleItem(
            type: .accommodation,
            title: "ホテル",
            startDate: tour.startDate,
            endDate: tour.endDate,
            tour: tour
        )

        try repository.update(
            tour,
            replacingScheduleItems: [addedItem]
        )

        let items = try context.fetch(
            FetchDescriptor<TourScheduleItem>()
        )
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "ホテル")
        XCTAssertTrue(items.first?.tour === tour)
    }

    func testDeletingTourCascadesSchedulesAndKeepsEvents() throws {
        let context = try makeContext()
        let tourRepository = SwiftDataTourRepository(modelContext: context)
        let eventRepository = SwiftDataEventRepository(modelContext: context)
        let event = LiveEvent(
            title: "Live",
            venue: "",
            startDate: Date()
        )
        try eventRepository.add(event)
        let tour = TourPlan(
            title: "Tour",
            startDate: event.startDate,
            endDate: event.startDate.addingTimeInterval(86400)
        )
        event.tour = tour
        tour.events = [event]
        tour.scheduleItems = [
            TourScheduleItem(
                type: .accommodation,
                title: "ホテル",
                startDate: tour.startDate,
                endDate: tour.endDate,
                tour: tour
            )
        ]
        try tourRepository.add(tour)

        try tourRepository.delete(tour)

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<TourPlan>()).isEmpty
        )
        XCTAssertTrue(
            try context.fetch(FetchDescriptor<TourScheduleItem>()).isEmpty
        )
        let remainingEvents = try context.fetch(
            FetchDescriptor<LiveEvent>()
        )
        XCTAssertEqual(remainingEvents.count, 1)
        XCTAssertNil(remainingEvents.first?.tour)
    }

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: LiveEvent.self,
            EventExpense.self,
            TourPlan.self,
            TourScheduleItem.self,
            configurations: configuration
        )
        return ModelContext(container)
    }
}
