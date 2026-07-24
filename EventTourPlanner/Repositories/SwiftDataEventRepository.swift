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

    func delete(_ event: LiveEvent) throws {
        modelContext.delete(event)
        try modelContext.save()
    }
}
