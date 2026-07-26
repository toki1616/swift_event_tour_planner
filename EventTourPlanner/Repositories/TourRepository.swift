import Foundation

@MainActor
protocol TourRepository {
    func fetchTours() throws -> [TourPlan]
    func add(_ tour: TourPlan) throws
    func update(
        _ tour: TourPlan,
        replacingScheduleItems scheduleItems: [TourScheduleItem]
    ) throws
    func delete(_ tour: TourPlan) throws
    func addScheduleItem(_ item: TourScheduleItem, to tour: TourPlan) throws
    func updateScheduleItem(_ item: TourScheduleItem) throws
    func deleteScheduleItem(_ item: TourScheduleItem) throws
}
