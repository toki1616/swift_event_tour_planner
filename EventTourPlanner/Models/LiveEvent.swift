import Foundation
import SwiftData

@Model
final class LiveEvent {
    var title: String
    var venue: String
    var startDate: Date

    init(
        title: String,
        venue: String,
        startDate: Date
    ) {
        self.title = title
        self.venue = venue
        self.startDate = startDate
    }
}
