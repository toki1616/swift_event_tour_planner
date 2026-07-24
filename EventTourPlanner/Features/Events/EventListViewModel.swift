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
            websiteURL: websiteURL,
            electronicTicketURL: electronicTicketURL,
            meetupDate: meetupDate,
            doorsOpenDate: doorsOpenDate,
            startDate: startDate,
            scheduledEndDate: scheduledEndDate
        ) else { return false }

        do {
            let event = LiveEvent(
                title: input.title,
                venue: input.venue,
                websiteURL: input.websiteURL,
                electronicTicketURL: input.electronicTicketURL,
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
                    createdAt: draft.createdAt,
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
        budget: Int,
        expenses: [ExpenseDraft]
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            venue: venue,
            websiteURL: websiteURL,
            electronicTicketURL: electronicTicketURL,
            meetupDate: meetupDate,
            doorsOpenDate: doorsOpenDate,
            startDate: startDate,
            scheduledEndDate: scheduledEndDate
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
        event.websiteURL = input.websiteURL
        event.electronicTicketURL = input.electronicTicketURL
        event.eventType = eventType
        event.meetupDate = meetupDate
        event.doorsOpenDate = doorsOpenDate
        event.startDate = input.startDate
        event.scheduledEndDate = scheduledEndDate
        event.budget = max(budget, 0)

        do {
            let replacementExpenses = expenses.map { draft in
                EventExpense(
                    name: draft.name,
                    amount: draft.amount,
                    category: draft.category,
                    createdAt: draft.createdAt,
                    event: event
                )
            }
            try repository.update(event, replacingExpenses: replacementExpenses)
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

    private func validatedInput(
        title: String,
        venue: String,
        websiteURL: String,
        electronicTicketURL: String,
        meetupDate: Date,
        doorsOpenDate: Date,
        startDate: Date,
        scheduledEndDate: Date
    ) -> (
        title: String,
        venue: String,
        websiteURL: String,
        electronicTicketURL: String,
        startDate: Date
    )? {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            errorMessage = String(localized: "validation.event_name_required")
            return nil
        }

        guard
            meetupDate <= doorsOpenDate,
            doorsOpenDate <= startDate,
            startDate <= scheduledEndDate
        else {
            errorMessage = "集合時間、開場時間、開演時間、終演予定時間の順に設定してください。"
            return nil
        }

        let normalizedWebsiteURL = websiteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedElectronicTicketURL = electronicTicketURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedWebsiteURL.isEmpty || normalizedURL(from: normalizedWebsiteURL) != nil else {
            errorMessage = "サイトURLを正しく入力してください。"
            return nil
        }
        guard normalizedElectronicTicketURL.isEmpty || normalizedURL(from: normalizedElectronicTicketURL) != nil else {
            errorMessage = "電子チケットURLを正しく入力してください。"
            return nil
        }

        return (
            normalizedTitle,
            venue.trimmingCharacters(in: .whitespacesAndNewlines),
            normalizedWebsiteURL,
            normalizedElectronicTicketURL,
            startDate
        )
    }

    func clearError() {
        errorMessage = nil
    }

    private func normalizedURL(from input: String) -> URL? {
        let urlString = input.contains("://") ? input : "https://\(input)"
        guard
            let components = URLComponents(string: urlString),
            ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
            components.host?.contains(".") == true
        else {
            return nil
        }
        return components.url
    }
}
