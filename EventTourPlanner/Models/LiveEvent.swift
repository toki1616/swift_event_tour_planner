import Foundation
import SwiftData

@Model
final class LiveEvent {
    var title: String
    var venue: String
    var startDate: Date
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

    init(
        title: String,
        venue: String,
        startDate: Date,
        budget: Int = 0
    ) {
        self.title = title
        self.venue = venue
        self.startDate = startDate
        self.budget = budget
    }
}
