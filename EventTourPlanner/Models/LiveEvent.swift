import Foundation
import SwiftData

@Model
final class LiveEvent {
    var title: String
    var venue: String
    var startDate: Date
    @Relationship(deleteRule: .cascade, inverse: \EventExpense.event)
    var expenses: [EventExpense] = []

    var totalExpense: Int {
        expenses.reduce(0) { $0 + $1.amount }
    }

    init(
        title: String,
        venue: String,
        startDate: Date
    ) {
        self.title = title
        self.venue = venue
        self.startDate = startDate
    }
}
