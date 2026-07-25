import Foundation
import SwiftData

@MainActor
final class SwiftDataTourRepository: TourRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchTours() throws -> [TourPlan] {
        let descriptor = FetchDescriptor<TourPlan>(
            sortBy: [SortDescriptor(\.startDate)]
        )
        return try modelContext.fetch(descriptor)
    }

    func add(_ tour: TourPlan) throws {
        modelContext.insert(tour)
        try modelContext.save()
    }

    func update(_ tour: TourPlan) throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func delete(_ tour: TourPlan) throws {
        modelContext.delete(tour)
        try modelContext.save()
    }
}
