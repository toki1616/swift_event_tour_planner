import Foundation
import Observation

@MainActor
@Observable
final class EventListViewModel {
    private let repository: any EventRepository

    private(set) var events: [LiveEvent] = []
    private(set) var errorMessage: String?

    init(repository: any EventRepository) {
        self.repository = repository
    }

    func loadEvents() {
        do {
            events = try repository.fetchEvents()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func addEvent(
        title: String,
        venue: String,
        websiteURL: String,
        electronicTicketURL: String,
        eventType: EventType,
        meetupDate: Date,
        doorsOpenDate: Date,
        startDate: Date,
        scheduledEndDate: Date,
        budget: Int,
        expenses: [ExpenseDraft] = []
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            venue: venue,
            startDate: startDate
        ) else { return false }

        do {
            let event = LiveEvent(
                title: input.title,
                venue: input.venue,
                websiteURL: websiteURL.trimmingCharacters(in: .whitespacesAndNewlines),
                electronicTicketURL: electronicTicketURL.trimmingCharacters(in: .whitespacesAndNewlines),
                eventType: eventType,
                meetupDate: meetupDate,
                doorsOpenDate: doorsOpenDate,
                startDate: input.startDate,
                scheduledEndDate: scheduledEndDate,
                budget: max(budget, 0)
            )
            event.expenses = expenses.map { draft in
                EventExpense(
                    name: draft.name,
                    amount: draft.amount,
                    category: draft.category,
                    event: event
                )
            }
            try repository.add(event)
            loadEvents()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func updateEvent(
        _ event: LiveEvent,
        title: String,
        venue: String,
        websiteURL: String,
        electronicTicketURL: String,
        eventType: EventType,
        meetupDate: Date,
        doorsOpenDate: Date,
        startDate: Date,
        scheduledEndDate: Date,
        budget: Int
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            venue: venue,
            startDate: startDate
        ) else { return false }

        let previousValues = (
            title: event.title,
            venue: event.venue,
            websiteURL: event.websiteURL,
            electronicTicketURL: event.electronicTicketURL,
            eventType: event.eventType,
            meetupDate: event.meetupDate,
            doorsOpenDate: event.doorsOpenDate,
            startDate: event.startDate,
            scheduledEndDate: event.scheduledEndDate,
            budget: event.budget
        )

        event.title = input.title
        event.venue = input.venue
        event.websiteURL = websiteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        event.electronicTicketURL = electronicTicketURL.trimmingCharacters(in: .whitespacesAndNewlines)
        event.eventType = eventType
        event.meetupDate = meetupDate
        event.doorsOpenDate = doorsOpenDate
        event.startDate = input.startDate
        event.scheduledEndDate = scheduledEndDate
        event.budget = max(budget, 0)

        do {
            try repository.update(event)
            loadEvents()
            return true
        } catch {
            event.title = previousValues.title
            event.venue = previousValues.venue
            event.websiteURL = previousValues.websiteURL
            event.electronicTicketURL = previousValues.electronicTicketURL
            event.eventType = previousValues.eventType
            event.meetupDate = previousValues.meetupDate
            event.doorsOpenDate = previousValues.doorsOpenDate
            event.startDate = previousValues.startDate
            event.scheduledEndDate = previousValues.scheduledEndDate
            event.budget = previousValues.budget
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteEvent(_ event: LiveEvent) {
        do {
            try repository.delete(event)
            loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func addExpense(
        name: String,
        amount: Int,
        category: ExpenseCategory,
        to event: LiveEvent
    ) -> Bool {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount > 0 else {
            errorMessage = String(localized: "validation.expense_amount_positive")
            return false
        }

        do {
            try repository.addExpense(
                EventExpense(
                    name: normalizedName,
                    amount: amount,
                    category: category
                ),
                to: event
            )
            loadEvents()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func updateExpense(
        _ expense: EventExpense,
        name: String,
        amount: Int,
        category: ExpenseCategory
    ) -> Bool {
        guard amount > 0 else {
            errorMessage = String(localized: "validation.expense_amount_positive")
            return false
        }

        let previousValues = (
            name: expense.name,
            amount: expense.amount,
            category: expense.category
        )

        expense.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        expense.amount = amount
        expense.category = category

        do {
            try repository.updateExpense(expense)
            loadEvents()
            return true
        } catch {
            expense.name = previousValues.name
            expense.amount = previousValues.amount
            expense.category = previousValues.category
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteExpense(_ expense: EventExpense) {
        do {
            try repository.deleteExpense(expense)
            loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func validatedInput(
        title: String,
        venue: String,
        startDate: Date
    ) -> (title: String, venue: String, startDate: Date)? {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            errorMessage = String(localized: "validation.event_name_required")
            return nil
        }

        return (
            normalizedTitle,
            venue.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate
        )
    }
}
