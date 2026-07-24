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
        startDate: Date,
        budget: Int
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            venue: venue,
            startDate: startDate
        ) else { return false }

        do {
            try repository.add(
                LiveEvent(
                    title: input.title,
                    venue: input.venue,
                    startDate: input.startDate,
                    budget: max(budget, 0)
                )
            )
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
        startDate: Date,
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
            startDate: event.startDate,
            budget: event.budget
        )

        event.title = input.title
        event.venue = input.venue
        event.startDate = input.startDate
        event.budget = max(budget, 0)

        do {
            try repository.update(event)
            loadEvents()
            return true
        } catch {
            event.title = previousValues.title
            event.venue = previousValues.venue
            event.startDate = previousValues.startDate
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
        guard !normalizedName.isEmpty else {
            errorMessage = String(localized: "validation.expense_name_required")
            return false
        }
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
