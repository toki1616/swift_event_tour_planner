import Foundation
import SwiftData

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case ticket
    case transportation
    case accommodation
    case goods
    case food
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ticket: String(localized: "expense.category.ticket")
        case .transportation: String(localized: "expense.category.transportation")
        case .accommodation: String(localized: "expense.category.accommodation")
        case .goods: String(localized: "expense.category.goods")
        case .food: String(localized: "expense.category.food")
        case .other: String(localized: "expense.category.other")
        }
    }

    var systemImage: String {
        switch self {
        case .ticket: "ticket"
        case .transportation: "tram"
        case .accommodation: "bed.double"
        case .goods: "bag"
        case .food: "fork.knife"
        case .other: "ellipsis.circle"
        }
    }
}

struct ExpenseDraft: Identifiable {
    let id: UUID
    var name: String
    var amount: Int
    var category: ExpenseCategory
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Int,
        category: ExpenseCategory,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.createdAt = createdAt
    }
}

@Model
final class EventExpense {
    var name: String
    var amount: Int
    var createdAt: Date
    var categoryRawValue: String = ExpenseCategory.other.rawValue
    var event: LiveEvent?

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        name: String,
        amount: Int,
        category: ExpenseCategory,
        createdAt: Date = Date(),
        event: LiveEvent? = nil
    ) {
        self.name = name
        self.amount = amount
        self.categoryRawValue = category.rawValue
        self.createdAt = createdAt
        self.event = event
    }
}
