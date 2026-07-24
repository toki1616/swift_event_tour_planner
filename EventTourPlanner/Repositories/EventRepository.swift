import Foundation

@MainActor
protocol EventRepository {
    func fetchEvents() throws -> [LiveEvent]
    func add(_ event: LiveEvent) throws
    func update(_ event: LiveEvent) throws
    func delete(_ event: LiveEvent) throws
    func addExpense(_ expense: EventExpense, to event: LiveEvent) throws
    func deleteExpense(_ expense: EventExpense) throws
}
