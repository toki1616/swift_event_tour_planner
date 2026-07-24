import Foundation
import SwiftData

enum EventType: String, CaseIterable, Identifiable {
    case live

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: String(localized: "event.type.live")
        }
    }

    func defaultMeetupDate(for startDate: Date) -> Date {
        Calendar.autoupdatingCurrent.date(byAdding: .hour, value: -2, to: startDate)
            ?? startDate
    }

    func defaultDoorsOpenDate(for startDate: Date) -> Date {
        Calendar.autoupdatingCurrent.date(byAdding: .hour, value: -1, to: startDate)
            ?? startDate
    }

    func defaultScheduledEndDate(for startDate: Date) -> Date {
        Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 2, to: startDate)
            ?? startDate
    }
}

@Model
final class LiveEvent {
    var title: String
    var venue: String
    var eventTypeRawValue: String = EventType.live.rawValue
    var meetupDate: Date?
    var doorsOpenDate: Date?
    var startDate: Date
    var scheduledEndDate: Date?
    var budget: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \EventExpense.event)
    var expenses: [EventExpense] = []

    var totalExpense: Int {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var remainingBudget: Int {
        budget - totalExpense
    }

    var budgetUsageRate: Double {
        guard budget > 0 else { return 0 }
        return Double(totalExpense) / Double(budget)
    }

    var eventType: EventType {
        get { EventType(rawValue: eventTypeRawValue) ?? .live }
        set { eventTypeRawValue = newValue.rawValue }
    }

    init(
        title: String,
        venue: String,
        eventType: EventType = .live,
        meetupDate: Date? = nil,
        doorsOpenDate: Date? = nil,
        startDate: Date,
        scheduledEndDate: Date? = nil,
        budget: Int = 0
    ) {
        self.title = title
        self.venue = venue
        self.eventTypeRawValue = eventType.rawValue
        self.meetupDate = meetupDate
        self.doorsOpenDate = doorsOpenDate
        self.startDate = startDate
        self.scheduledEndDate = scheduledEndDate
        self.budget = budget
    }
}
