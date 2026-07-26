import Foundation
import SwiftData

@Model
final class TourPlan {
    var title: String
    var startDate: Date
    var endDate: Date
    var budget: Int
    var notes: String
    @Relationship(deleteRule: .nullify, inverse: \LiveEvent.tour)
    var events: [LiveEvent] = []

    var totalExpense: Int {
        events.reduce(0) { $0 + $1.totalExpense }
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
        startDate: Date,
        endDate: Date,
        budget: Int = 0,
        notes: String = ""
    ) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.notes = notes
    }
}
