import Foundation
import SwiftData

@Model
final class EventExpense {
    var name: String
    var amount: Int
    var createdAt: Date
    var event: LiveEvent?

    init(
        name: String,
        amount: Int,
        createdAt: Date = Date(),
        event: LiveEvent? = nil
    ) {
        self.name = name
        self.amount = amount
        self.createdAt = createdAt
        self.event = event
    }
}
