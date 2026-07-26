import Foundation
import SwiftData

enum TourScheduleType: String, CaseIterable, Identifiable {
    case transportation
    case accommodation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .transportation:
            String(localized: "tour.schedule.type.transportation")
        case .accommodation:
            String(localized: "tour.schedule.type.accommodation")
        }
    }

    var systemImage: String {
        switch self {
        case .transportation: "tram.fill"
        case .accommodation: "bed.double.fill"
        }
    }
}

struct TourScheduleDraft: Identifiable {
    let id: UUID
    var type: TourScheduleType
    var title: String
    var startDate: Date
    var endDate: Date
    var departureLocation: String
    var arrivalLocation: String
    var reservationNumber: String
    var notes: String
    let sourceItem: TourScheduleItem?

    init(
        id: UUID = UUID(),
        type: TourScheduleType,
        title: String,
        startDate: Date,
        endDate: Date,
        departureLocation: String = "",
        arrivalLocation: String = "",
        reservationNumber: String = "",
        notes: String = "",
        sourceItem: TourScheduleItem? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.departureLocation = departureLocation
        self.arrivalLocation = arrivalLocation
        self.reservationNumber = reservationNumber
        self.notes = notes
        self.sourceItem = sourceItem
    }
}

enum TourScheduleDateRange {
    static func clampedDates(
        startDate: Date,
        endDate: Date,
        tourStartDate: Date,
        tourEndDate: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> (startDate: Date, endDate: Date) {
        let endLimit = calendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: tourEndDate
        ) ?? tourEndDate
        let clampedStartDate = min(
            max(startDate, tourStartDate),
            endLimit
        )
        let clampedEndDate = min(
            max(endDate, clampedStartDate),
            endLimit
        )
        return (clampedStartDate, clampedEndDate)
    }
}

@Model
final class TourScheduleItem {
    var typeRawValue: String
    var title: String
    var startDate: Date
    var endDate: Date
    var departureLocation: String
    var arrivalLocation: String
    var reservationNumber: String
    var notes: String
    var tour: TourPlan?

    var type: TourScheduleType {
        get { TourScheduleType(rawValue: typeRawValue) ?? .transportation }
        set { typeRawValue = newValue.rawValue }
    }

    init(
        type: TourScheduleType,
        title: String,
        startDate: Date,
        endDate: Date,
        departureLocation: String = "",
        arrivalLocation: String = "",
        reservationNumber: String = "",
        notes: String = "",
        tour: TourPlan? = nil
    ) {
        self.typeRawValue = type.rawValue
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.departureLocation = departureLocation
        self.arrivalLocation = arrivalLocation
        self.reservationNumber = reservationNumber
        self.notes = notes
        self.tour = tour
    }
}
