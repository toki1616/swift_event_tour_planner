import Foundation

@MainActor
protocol TourRepository {
    func fetchTours() throws -> [TourPlan]
    func add(_ tour: TourPlan) throws
    func update(_ tour: TourPlan) throws
    func delete(_ tour: TourPlan) throws
}
