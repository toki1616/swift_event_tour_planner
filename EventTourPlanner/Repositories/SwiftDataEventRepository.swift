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

    func update(_ event: LiveEvent) throws {
        try modelContext.save()
    }

    func delete(_ event: LiveEvent) throws {
        modelContext.delete(event)
        try modelContext.save()
    }

    func addExpense(_ expense: EventExpense, to event: LiveEvent) throws {
        expense.event = event
        modelContext.insert(expense)
        try modelContext.save()
    }

    func updateExpense(_ expense: EventExpense) throws {
        try modelContext.save()
    }

    func deleteExpense(_ expense: EventExpense) throws {
        modelContext.delete(expense)
        try modelContext.save()
    }
}
