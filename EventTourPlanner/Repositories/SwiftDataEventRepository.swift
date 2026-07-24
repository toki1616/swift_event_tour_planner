import Foundation
import SwiftData

@MainActor
final class SwiftDataEventRepository: EventRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchEvents() throws -> [LiveEvent] {
        let descriptor = FetchDescriptor<LiveEvent>(
            sortBy: [SortDescriptor(\.startDate)]
        )
        return try modelContext.fetch(descriptor)
    }

    func add(_ event: LiveEvent) throws {
        modelContext.insert(event)
        try modelContext.save()
    }

    func update(_ event: LiveEvent, replacingExpenses expenses: [EventExpense]) throws {
        let previousExpenses = event.expenses
        let deletedExpenses = previousExpenses.filter { previousExpense in
            !expenses.contains { $0 === previousExpense }
        }

        for expense in deletedExpenses {
            modelContext.delete(expense)
        }
        event.expenses = expenses
        for expense in expenses where expense.modelContext == nil {
            expense.event = event
            modelContext.insert(expense)
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func delete(_ event: LiveEvent) throws {
        modelContext.delete(event)
        try modelContext.save()
    }
}
