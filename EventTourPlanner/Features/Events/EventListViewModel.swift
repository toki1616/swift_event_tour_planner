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
    func addEvent(title: String, venue: String, startDate: Date) -> Bool {
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
                    startDate: input.startDate
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
        startDate: Date
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            venue: venue,
            startDate: startDate
        ) else { return false }

        let previousValues = (
            title: event.title,
            venue: event.venue,
            startDate: event.startDate
        )

        event.title = input.title
        event.venue = input.venue
        event.startDate = input.startDate

        do {
            try repository.update(event)
            loadEvents()
            return true
        } catch {
            event.title = previousValues.title
            event.venue = previousValues.venue
            event.startDate = previousValues.startDate
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
