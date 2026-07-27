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

    @discardableResult
    func loadTours() -> Bool {
        do {
            tours = try repository.fetchTours()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func addTour(
        title: String,
        startDate: Date,
        endDate: Date,
        budget: Int,
        notes: String,
        events: [LiveEvent],
        scheduleItems: [TourScheduleDraft]
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            startDate: startDate,
            endDate: endDate,
            events: events,
            scheduleItems: scheduleItems
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
            tour.scheduleItems = scheduleItems.map {
                makeScheduleItem(from: $0, tour: tour)
            }
            try repository.add(tour)
            tours.append(tour)
            sortTours()
            errorMessage = nil
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
        events: [LiveEvent],
        scheduleItems: [TourScheduleDraft]
    ) -> Bool {
        guard let input = validatedInput(
            title: title,
            startDate: startDate,
            endDate: endDate,
            events: events,
            scheduleItems: scheduleItems
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
            let replacementItems = scheduleItems.map { draft in
                if let item = draft.sourceItem {
                    apply(draft, to: item)
                    return item
                }
                return makeScheduleItem(from: draft, tour: tour)
            }
            try repository.update(
                tour,
                replacingScheduleItems: replacementItems
            )
            sortTours()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteTour(_ tour: TourPlan) {
        do {
            try repository.delete(tour)
            tours.removeAll { $0 === tour }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func addScheduleItem(
        to tour: TourPlan,
        type: TourScheduleType,
        title: String,
        startDate: Date,
        endDate: Date,
        departureLocation: String,
        arrivalLocation: String,
        reservationNumber: String,
        notes: String
    ) -> Bool {
        guard let input = validatedScheduleInput(
            tour: tour,
            title: title,
            startDate: startDate,
            endDate: endDate
        ) else { return false }

        let item = TourScheduleItem(
            type: type,
            title: input.title,
            startDate: input.startDate,
            endDate: input.endDate,
            departureLocation: normalized(departureLocation),
            arrivalLocation: normalized(arrivalLocation),
            reservationNumber: normalized(reservationNumber),
            notes: normalized(notes)
        )

        do {
            try repository.addScheduleItem(item, to: tour)
            if !tour.scheduleItems.contains(where: { $0 === item }) {
                tour.scheduleItems.append(item)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func updateScheduleItem(
        _ item: TourScheduleItem,
        type: TourScheduleType,
        title: String,
        startDate: Date,
        endDate: Date,
        departureLocation: String,
        arrivalLocation: String,
        reservationNumber: String,
        notes: String
    ) -> Bool {
        guard
            let tour = item.tour,
            let input = validatedScheduleInput(
                tour: tour,
                title: title,
                startDate: startDate,
                endDate: endDate
            )
        else { return false }

        item.type = type
        item.title = input.title
        item.startDate = input.startDate
        item.endDate = input.endDate
        item.departureLocation = normalized(departureLocation)
        item.arrivalLocation = normalized(arrivalLocation)
        item.reservationNumber = normalized(reservationNumber)
        item.notes = normalized(notes)

        do {
            try repository.updateScheduleItem(item)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func deleteScheduleItem(_ item: TourScheduleItem) -> Bool {
        let tour = item.tour
        do {
            try repository.deleteScheduleItem(item)
            tour?.scheduleItems.removeAll { $0 === item }
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func validatedInput(
        title: String,
        startDate: Date,
        endDate: Date,
        events: [LiveEvent],
        scheduleItems: [TourScheduleDraft]
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
        guard scheduleItems.allSatisfy({
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.startDate <= $0.endDate
                && firstDay <= $0.startDate
                && $0.endDate < dayAfterLast
        }) else {
            errorMessage = String(localized: "validation.schedule_outside_tour")
            return nil
        }
        return (normalizedTitle, startDate, endDate)
    }

    private func validatedScheduleInput(
        tour: TourPlan,
        title: String,
        startDate: Date,
        endDate: Date
    ) -> (title: String, startDate: Date, endDate: Date)? {
        let normalizedTitle = normalized(title)
        guard !normalizedTitle.isEmpty else {
            errorMessage = String(localized: "validation.schedule_title_required")
            return nil
        }
        guard startDate <= endDate else {
            errorMessage = String(localized: "validation.schedule_date_order")
            return nil
        }

        let calendar = Calendar.autoupdatingCurrent
        let firstDay = calendar.startOfDay(for: tour.startDate)
        guard let dayAfterLast = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: tour.endDate)
        ), firstDay <= startDate, endDate < dayAfterLast else {
            errorMessage = String(localized: "validation.schedule_outside_tour")
            return nil
        }
        return (normalizedTitle, startDate, endDate)
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sortTours() {
        tours.sort { $0.startDate < $1.startDate }
    }

    private func makeScheduleItem(
        from draft: TourScheduleDraft,
        tour: TourPlan
    ) -> TourScheduleItem {
        TourScheduleItem(
            type: draft.type,
            title: normalized(draft.title),
            startDate: draft.startDate,
            endDate: draft.endDate,
            departureLocation: normalized(draft.departureLocation),
            arrivalLocation: normalized(draft.arrivalLocation),
            reservationNumber: normalized(draft.reservationNumber),
            notes: normalized(draft.notes),
            tour: tour
        )
    }

    private func apply(
        _ draft: TourScheduleDraft,
        to item: TourScheduleItem
    ) {
        item.type = draft.type
        item.title = normalized(draft.title)
        item.startDate = draft.startDate
        item.endDate = draft.endDate
        item.departureLocation = normalized(draft.departureLocation)
        item.arrivalLocation = normalized(draft.arrivalLocation)
        item.reservationNumber = normalized(draft.reservationNumber)
        item.notes = normalized(draft.notes)
    }
}
