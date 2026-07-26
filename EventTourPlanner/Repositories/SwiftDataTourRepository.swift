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

    func update(
        _ tour: TourPlan,
        replacingScheduleItems scheduleItems: [TourScheduleItem]
    ) throws {
        let previousItems = tour.scheduleItems
        let deletedItems = previousItems.filter { previousItem in
            !scheduleItems.contains { $0 === previousItem }
        }
        for item in deletedItems {
            modelContext.delete(item)
        }
        tour.scheduleItems = scheduleItems
        for item in scheduleItems where item.modelContext == nil {
            item.tour = tour
            modelContext.insert(item)
        }
        try saveOrRollback()
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

    func addScheduleItem(_ item: TourScheduleItem, to tour: TourPlan) throws {
        item.tour = tour
        modelContext.insert(item)
        try saveOrRollback()
    }

    func updateScheduleItem(_ item: TourScheduleItem) throws {
        try saveOrRollback()
    }

    func deleteScheduleItem(_ item: TourScheduleItem) throws {
        modelContext.delete(item)
        try saveOrRollback()
    }

    private func saveOrRollback() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
