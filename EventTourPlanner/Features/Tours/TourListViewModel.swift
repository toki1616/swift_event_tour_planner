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
            endDate: endDate,
            events: events
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
            endDate: endDate,
            events: events
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
        endDate: Date,
        events: [LiveEvent]
    ) -> (title: String, startDate: Date, endDate: Date)? {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            errorMessage = String(localized: "validation.tour_name_required")
            return nil
        }
        guard startDate <= endDate else {
            errorMessage = String(localized: "validation.tour_date_order")
            return nil
        }
        let calendar = Calendar.autoupdatingCurrent
        let firstDay = calendar.startOfDay(for: startDate)
        guard let dayAfterLast = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: endDate)
        ) else {
            errorMessage = String(localized: "validation.tour_period_invalid")
            return nil
        }
        guard events.allSatisfy({
            firstDay <= $0.startDate && $0.startDate < dayAfterLast
        }) else {
            errorMessage = String(localized: "validation.tour_event_outside_period")
            return nil
        }
        return (normalizedTitle, startDate, endDate)
    }
}
