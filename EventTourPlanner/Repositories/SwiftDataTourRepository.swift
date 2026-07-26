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
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
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
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
