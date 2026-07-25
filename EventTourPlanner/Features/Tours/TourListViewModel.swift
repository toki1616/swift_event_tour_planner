import Foundation
import Observation

@MainActor
@Observable
final class TourListViewModel {
    private let repository: any TourRepository

    private(set) var tours: [TourPlan] = []
    private(set) var errorMessage: String?

    init(repository: any TourRepository) {
        self.repository = repository
    }

    func loadTours() {
        do {
            tours = try repository.fetchTours()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func addTour(
        title: String,
        startDate: Date,
        endDate: Date,
        budget: Int,
        notes: String,
        events: [LiveEvent]
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            startDate: startDate,
            endDate: endDate
        ) else { return false }

        do {
            let tour = TourPlan(
                title: input.title,
                startDate: input.startDate,
                endDate: input.endDate,
                budget: max(budget, 0),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            tour.events = events
            events.forEach { $0.tour = tour }
            try repository.add(tour)
            loadTours()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func updateTour(
        _ tour: TourPlan,
        title: String,
        startDate: Date,
        endDate: Date,
        budget: Int,
        notes: String,
        events: [LiveEvent]
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            startDate: startDate,
            endDate: endDate
        ) else { return false }

        tour.title = input.title
        tour.startDate = input.startDate
        tour.endDate = input.endDate
        tour.budget = max(budget, 0)
        tour.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let removedEvents = tour.events.filter { previousEvent in
            !events.contains { $0 === previousEvent }
        }
        removedEvents.forEach { $0.tour = nil }
        tour.events = events
        events.forEach { $0.tour = tour }

        do {
            try repository.update(tour)
            loadTours()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteTour(_ tour: TourPlan) {
        do {
            try repository.delete(tour)
            loadTours()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func validatedInput(
        title: String,
        startDate: Date,
        endDate: Date
    ) -> (title: String, startDate: Date, endDate: Date)? {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            errorMessage = "ツアー名を入力してください。"
            return nil
        }
        guard startDate <= endDate else {
            errorMessage = "終了日は開始日以降に設定してください。"
            return nil
        }
        return (normalizedTitle, startDate, endDate)
    }
}
