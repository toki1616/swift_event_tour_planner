import XCTest
@testable import EventTourPlanner

@MainActor
final class EventListViewModelTests: XCTestCase {
    func testLoadEventsSetsEventsAndClearsError() {
        let repository = EventRepositoryStub()
        let event = makeEvent()
        repository.fetchedEvents = [event]
        let viewModel = EventListViewModel(repository: repository)

        viewModel.loadEvents()

        XCTAssertEqual(viewModel.events.count, 1)
        XCTAssertTrue(viewModel.events.first === event)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadEventsKeepsPreviousEventsWhenFetchFails() {
        let repository = EventRepositoryStub()
        repository.fetchedEvents = [makeEvent(title: "既存")]
        let viewModel = EventListViewModel(repository: repository)
        viewModel.loadEvents()
        repository.fetchError = EventRepositoryStub.testError

        viewModel.loadEvents()

        XCTAssertEqual(viewModel.events.first?.title, "既存")
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testAddEventNormalizesInputAndCreatesExpenses() {
        let repository = EventRepositoryStub()
        let viewModel = EventListViewModel(repository: repository)
        let dates = validDates()

        let result = viewModel.addEvent(
            title: "  Live  ",
            venue: "  Tokyo Dome  ",
            websiteURL: "  example.com  ",
            electronicTicketURL: "  https://ticket.example.com  ",
            eventType: .live,
            meetupDate: dates.meetup,
            doorsOpenDate: dates.doorsOpen,
            startDate: dates.start,
            scheduledEndDate: dates.end,
            budget: -1_000,
            expenses: [
                ExpenseDraft(
                    name: "",
                    amount: 8_000,
                    category: .transportation
                )
            ]
        )

        XCTAssertTrue(result)
        let event = repository.addedEvents.first
        XCTAssertEqual(event?.title, "Live")
        XCTAssertEqual(event?.venue, "Tokyo Dome")
        XCTAssertEqual(event?.websiteURL, "example.com")
        XCTAssertEqual(event?.electronicTicketURL, "https://ticket.example.com")
        XCTAssertEqual(event?.budget, 0)
        XCTAssertEqual(event?.expenses.count, 1)
        XCTAssertTrue(event?.expenses.first?.event === event)
    }

    func testAddEventRejectsInvalidInputsWithoutCallingRepository() {
        let invalidInputs: [(String, String, (EventDates) -> EventDates)] = [
            ("name", "   ", { $0 }),
            ("schedule", "Live", {
                EventDates(
                    meetup: $0.start,
                    doorsOpen: $0.meetup,
                    start: $0.doorsOpen,
                    end: $0.end
                )
            })
        ]

        for (_, title, transform) in invalidInputs {
            let repository = EventRepositoryStub()
            let viewModel = EventListViewModel(repository: repository)
            let dates = transform(validDates())

            let result = viewModel.addEvent(
                title: title,
                venue: "",
                websiteURL: "",
                electronicTicketURL: "",
                eventType: .live,
                meetupDate: dates.meetup,
                doorsOpenDate: dates.doorsOpen,
                startDate: dates.start,
                scheduledEndDate: dates.end,
                budget: 0
            )

            XCTAssertFalse(result)
            XCTAssertTrue(repository.addedEvents.isEmpty)
            XCTAssertNotNil(viewModel.errorMessage)
        }
    }

    func testAddEventRejectsInvalidURLs() {
        for urls in [
            ("invalid", ""),
            ("", "ftp://ticket.example.com")
        ] {
            let repository = EventRepositoryStub()
            let viewModel = EventListViewModel(repository: repository)
            let dates = validDates()

            let result = viewModel.addEvent(
                title: "Live",
                venue: "",
                websiteURL: urls.0,
                electronicTicketURL: urls.1,
                eventType: .live,
                meetupDate: dates.meetup,
                doorsOpenDate: dates.doorsOpen,
                startDate: dates.start,
                scheduledEndDate: dates.end,
                budget: 0
            )

            XCTAssertFalse(result)
            XCTAssertTrue(repository.addedEvents.isEmpty)
        }
    }

    func testUpdateEventPassesReplacementExpenses() {
        let repository = EventRepositoryStub()
        let viewModel = EventListViewModel(repository: repository)
        let event = makeEvent()
        let existingExpense = EventExpense(
            name: "旧交通費",
            amount: 1_000,
            category: .transportation,
            event: event
        )
        event.expenses = [existingExpense]
        let dates = validDates()

        let result = viewModel.updateEvent(
            event,
            title: "Updated",
            venue: "Osaka",
            websiteURL: "",
            electronicTicketURL: "",
            eventType: .live,
            meetupDate: dates.meetup,
            doorsOpenDate: dates.doorsOpen,
            startDate: dates.start,
            scheduledEndDate: dates.end,
            budget: 20_000,
            expenses: [
                ExpenseDraft(
                    name: "新交通費",
                    amount: 2_000,
                    category: .transportation,
                    sourceExpense: existingExpense
                ),
                ExpenseDraft(
                    name: "",
                    amount: 5_000,
                    category: .goods
                )
            ]
        )

        XCTAssertTrue(result)
        XCTAssertEqual(repository.replacementExpenses.count, 2)
        XCTAssertTrue(repository.replacementExpenses.first === existingExpense)
        XCTAssertEqual(existingExpense.name, "新交通費")
        XCTAssertEqual(existingExpense.amount, 2_000)
        XCTAssertEqual(event.title, "Updated")
    }

    func testUpdateEventRestoresEventValuesWhenRepositoryFails() {
        let repository = EventRepositoryStub()
        repository.updateError = EventRepositoryStub.testError
        let viewModel = EventListViewModel(repository: repository)
        let event = makeEvent(title: "Before")
        let originalStartDate = event.startDate
        let dates = validDates()

        let result = viewModel.updateEvent(
            event,
            title: "After",
            venue: "Changed",
            websiteURL: "example.com",
            electronicTicketURL: "",
            eventType: .live,
            meetupDate: dates.meetup,
            doorsOpenDate: dates.doorsOpen,
            startDate: dates.start,
            scheduledEndDate: dates.end,
            budget: 10_000,
            expenses: []
        )

        XCTAssertFalse(result)
        XCTAssertEqual(event.title, "Before")
        XCTAssertEqual(event.startDate, originalStartDate)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testDeleteEventReportsRepositoryFailure() {
        let repository = EventRepositoryStub()
        repository.deleteError = EventRepositoryStub.testError
        let viewModel = EventListViewModel(repository: repository)

        viewModel.deleteEvent(makeEvent())

        XCTAssertNotNil(viewModel.errorMessage)
    }

    private func makeEvent(title: String = "Live") -> LiveEvent {
        LiveEvent(
            title: title,
            venue: "Tokyo",
            startDate: Date(timeIntervalSince1970: 1_800_000_000)
        )
    }

    private func validDates() -> EventDates {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        return EventDates(
            meetup: start.addingTimeInterval(-7200),
            doorsOpen: start.addingTimeInterval(-3600),
            start: start,
            end: start.addingTimeInterval(7200)
        )
    }
}

private struct EventDates {
    let meetup: Date
    let doorsOpen: Date
    let start: Date
    let end: Date
}

@MainActor
private final class EventRepositoryStub: EventRepository {
    static let testError = NSError(
        domain: "EventRepositoryStub",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "テストエラー"]
    )

    var fetchedEvents: [LiveEvent] = []
    var addedEvents: [LiveEvent] = []
    var updatedEvents: [LiveEvent] = []
    var deletedEvents: [LiveEvent] = []
    var replacementExpenses: [EventExpense] = []
    var fetchError: Error?
    var addError: Error?
    var updateError: Error?
    var deleteError: Error?

    func fetchEvents() throws -> [LiveEvent] {
        if let fetchError { throw fetchError }
        return fetchedEvents
    }

    func add(_ event: LiveEvent) throws {
        if let addError { throw addError }
        addedEvents.append(event)
        fetchedEvents.append(event)
    }

    func update(
        _ event: LiveEvent,
        replacingExpenses expenses: [EventExpense]
    ) throws {
        if let updateError { throw updateError }
        updatedEvents.append(event)
        replacementExpenses = expenses
        fetchedEvents = [event]
    }

    func delete(_ event: LiveEvent) throws {
        if let deleteError { throw deleteError }
        deletedEvents.append(event)
        fetchedEvents.removeAll { $0 === event }
    }
}
