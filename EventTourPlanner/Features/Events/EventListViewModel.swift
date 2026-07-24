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
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            errorMessage = "イベント名を入力してください。"
            return false
        }

        do {
            try repository.add(
                LiveEvent(
                    title: normalizedTitle,
                    venue: venue.trimmingCharacters(in: .whitespacesAndNewlines),
                    startDate: startDate
                )
            )
            loadEvents()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
