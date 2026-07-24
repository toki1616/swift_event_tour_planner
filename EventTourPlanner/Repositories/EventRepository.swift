import Foundation

@MainActor
protocol EventRepository {
    func fetchEvents() throws -> [LiveEvent]
    func add(_ event: LiveEvent) throws
    func update(_ event: LiveEvent, replacingExpenses expenses: [EventExpense]) throws
    func delete(_ event: LiveEvent) throws
}
